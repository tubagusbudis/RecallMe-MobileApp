-- Private schema for trigger/helper functions.
create schema if not exists private;

revoke all on schema private from public, anon, authenticated;

-- Profiles linked to Supabase Auth with unique lowercase username.
create table public.profiles (
    id uuid primary key
        references auth.users (id) on delete cascade,
    username text not null unique,
    display_name text,
    created_at timestamptz not null default now(),

    constraint profiles_username_format
        check (username ~ '^[a-z0-9_]{3,30}$')
);

-- Decks owned by authenticated users.
create table public.decks (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null
        references auth.users (id) on delete cascade,
    title text not null,
    description text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),

    constraint decks_title_not_empty
        check (length(btrim(title)) > 0)
);

-- Flashcards belong to a deck (text-only for MVP, single-queue baseline).
create table public.flashcards (
    id uuid primary key default gen_random_uuid(),
    deck_id uuid not null
        references public.decks (id) on delete cascade,
    question text not null,
    answer text not null,

    -- Single-queue baseline: new cards are immediately due (next_review_at = now()).
    repetitions integer not null default 0,
    interval_days integer not null default 0,
    ease_factor numeric(5, 3) not null default 2.500,

    next_review_at timestamptz not null default now(),
    last_review_at timestamptz,

    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),

    constraint flashcards_question_not_empty
        check (length(btrim(question)) > 0),

    constraint flashcards_answer_not_empty
        check (length(btrim(answer)) > 0),

    constraint flashcards_repetitions_non_negative
        check (repetitions >= 0),

    constraint flashcards_interval_non_negative
        check (interval_days >= 0),

    constraint flashcards_ease_factor_positive
        check (ease_factor > 0)
);

-- Review history stored separately; cascades cleanly when card or deck is deleted.
create table public.review_logs (
    id uuid primary key default gen_random_uuid(),

    flashcard_id uuid not null
        references public.flashcards (id) on delete cascade,
    user_id uuid not null
        references auth.users (id) on delete cascade,

    quality smallint not null,
    reviewed_at timestamptz not null,

    previous_interval integer,
    next_interval integer not null,

    idempotency_key uuid not null,
    created_at timestamptz not null default now(),

    constraint review_logs_quality_allowed
        check (quality in (1, 3, 4, 5)),

    constraint review_logs_previous_interval_non_negative
        check (previous_interval is null or previous_interval >= 0),

    constraint review_logs_next_interval_non_negative
        check (next_interval >= 0),

    constraint review_logs_user_idempotency_unique
        unique (user_id, idempotency_key)
);

-- Automatically maintain updated_at for mutable tables.
create or replace function private.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
    new.updated_at := now();
    return new;
end;
$$;

create trigger set_decks_updated_at
before update on public.decks
for each row
execute function private.set_updated_at();

create trigger set_flashcards_updated_at
before update on public.flashcards
for each row
execute function private.set_updated_at();

-- Create a profile with normalized username whenever Supabase Auth creates a user.
create or replace function private.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_username text;
begin
    v_username := lower(btrim(coalesce(
        new.raw_user_meta_data ->> 'username',
        split_part(new.email, '@', 1)
    )));

    insert into public.profiles (id, username, display_name)
    values (
        new.id,
        v_username,
        nullif(btrim(new.raw_user_meta_data ->> 'display_name'), '')
    )
    on conflict (id) do nothing;

    return new;
end;
$$;

create trigger on_auth_user_created
after insert on auth.users
for each row
execute function private.handle_new_user();

-- Indexes for the MVP's main access patterns.
create index decks_user_created_idx
    on public.decks (user_id, created_at desc);

create index flashcards_deck_created_idx
    on public.flashcards (deck_id, created_at);

create index flashcards_deck_due_idx
    on public.flashcards (deck_id, next_review_at asc);

create index review_logs_user_reviewed_idx
    on public.review_logs (user_id, reviewed_at desc);

create index review_logs_card_reviewed_idx
    on public.review_logs (flashcard_id, reviewed_at desc);
