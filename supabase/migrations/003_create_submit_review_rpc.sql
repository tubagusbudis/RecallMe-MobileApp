-- Grant access to the private schema only for the authenticated role.
grant usage on schema private to authenticated;

create or replace function private.submit_flashcard_review_impl(
    p_flashcard_id uuid,
    p_quality smallint,
    p_repetitions integer,
    p_interval_days integer,
    p_ease_factor numeric,
    p_reviewed_at timestamptz,
    p_next_review_at timestamptz,
    p_idempotency_key uuid,
    p_expected_updated_at timestamptz
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_user_id uuid;
    v_card public.flashcards%rowtype;
    v_existing public.review_logs%rowtype;
    v_log public.review_logs%rowtype;
begin
    v_user_id := (select auth.uid());

    if v_user_id is null then
        raise exception using
            errcode = '42501',
            message = 'AUTHENTICATION_REQUIRED';
    end if;

    if p_flashcard_id is null
       or p_idempotency_key is null
       or p_reviewed_at is null
       or p_next_review_at is null
       or p_expected_updated_at is null then
        raise exception using
            errcode = '22023',
            message = 'REQUIRED_ARGUMENT_MISSING';
    end if;

    if p_quality not in (1, 3, 4, 5) then
        raise exception using
            errcode = '22023',
            message = 'INVALID_REVIEW_QUALITY';
    end if;

    if p_repetitions < 0
       or p_interval_days < 0
       or p_ease_factor is null
       or p_ease_factor <= 0 then
        raise exception using
            errcode = '22023',
            message = 'INVALID_SCHEDULE_STATE';
    end if;

    -- Lock only a flashcard that belongs to the current authenticated user.
    select f.*
    into v_card
    from public.flashcards as f
    join public.decks as d
      on d.id = f.deck_id
    where f.id = p_flashcard_id
      and d.user_id = v_user_id
    for update of f;

    if not found then
        raise exception using
            errcode = 'P0002',
            message = 'FLASHCARD_NOT_FOUND';
    end if;

    -- Check idempotency after acquiring the row lock.
    select *
    into v_existing
    from public.review_logs
    where user_id = v_user_id
      and idempotency_key = p_idempotency_key;

    if found then
        if v_existing.flashcard_id <> p_flashcard_id
           or v_existing.quality <> p_quality then
            raise exception using
                errcode = '22023',
                message = 'IDEMPOTENCY_KEY_REUSED';
        end if;

        return jsonb_build_object(
            'review_log_id', v_existing.id,
            'flashcard_id', v_existing.flashcard_id,
            'quality', v_existing.quality,
            'reviewed_at', v_existing.reviewed_at,
            'next_interval_days', v_existing.next_interval,
            'already_processed', true
        );
    end if;

    -- Reject a result calculated from an old flashcard state.
    if v_card.updated_at is distinct from p_expected_updated_at then
        raise exception using
            errcode = '40001',
            message = 'STALE_FLASHCARD_STATE';
    end if;

    update public.flashcards
    set repetitions = p_repetitions,
        interval_days = p_interval_days,
        ease_factor = p_ease_factor,
        last_review_at = p_reviewed_at,
        next_review_at = p_next_review_at,
        updated_at = now()
    where id = p_flashcard_id;

    insert into public.review_logs (
        flashcard_id,
        user_id,
        quality,
        reviewed_at,
        previous_interval,
        next_interval,
        idempotency_key
    )
    values (
        p_flashcard_id,
        v_user_id,
        p_quality,
        p_reviewed_at,
        v_card.interval_days,
        p_interval_days,
        p_idempotency_key
    )
    returning * into v_log;

    return jsonb_build_object(
        'review_log_id', v_log.id,
        'flashcard_id', v_log.flashcard_id,
        'quality', v_log.quality,
        'reviewed_at', v_log.reviewed_at,
        'repetitions', p_repetitions,
        'interval_days', p_interval_days,
        'ease_factor', p_ease_factor,
        'next_review_at', p_next_review_at,
        'already_processed', false
    );
end;
$$;

revoke all on function private.submit_flashcard_review_impl(
    uuid, smallint, integer, integer, numeric,
    timestamptz, timestamptz, uuid, timestamptz
) from public, anon;

grant execute on function private.submit_flashcard_review_impl(
    uuid, smallint, integer, integer, numeric,
    timestamptz, timestamptz, uuid, timestamptz
) to authenticated;

create or replace function public.submit_flashcard_review(
    p_flashcard_id uuid,
    p_quality smallint,
    p_repetitions integer,
    p_interval_days integer,
    p_ease_factor numeric,
    p_reviewed_at timestamptz,
    p_next_review_at timestamptz,
    p_idempotency_key uuid,
    p_expected_updated_at timestamptz
)
returns jsonb
language sql
security invoker
set search_path = ''
as $$
    select private.submit_flashcard_review_impl(
        p_flashcard_id,
        p_quality,
        p_repetitions,
        p_interval_days,
        p_ease_factor,
        p_reviewed_at,
        p_next_review_at,
        p_idempotency_key,
        p_expected_updated_at
    );
$$;

revoke all on function public.submit_flashcard_review(
    uuid, smallint, integer, integer, numeric,
    timestamptz, timestamptz, uuid, timestamptz
) from public, anon;

grant execute on function public.submit_flashcard_review(
    uuid, smallint, integer, integer, numeric,
    timestamptz, timestamptz, uuid, timestamptz
) to authenticated;
