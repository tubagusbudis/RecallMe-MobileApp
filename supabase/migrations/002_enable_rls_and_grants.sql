-- Enable RLS on all user-owned tables.
alter table public.profiles enable row level security;
alter table public.decks enable row level security;
alter table public.flashcards enable row level security;
alter table public.review_logs enable row level security;

-- Start from no client privileges, then grant only required operations.
revoke all on table public.profiles from anon, authenticated;
revoke all on table public.decks from anon, authenticated;
revoke all on table public.flashcards from anon, authenticated;
revoke all on table public.review_logs from anon, authenticated;

-- Profiles are created by the Auth trigger.
grant select, update on table public.profiles to authenticated;
grant select, insert, update, delete on table public.decks to authenticated;
grant select, insert, update, delete on table public.flashcards to authenticated;

-- Client can read review history, but cannot write it directly.
-- Writes happen through the review RPC.
grant select on table public.review_logs to authenticated;

-- PROFILES: user can read/update only their own row.
create policy profiles_select_own
on public.profiles
for select
to authenticated
using ((select auth.uid()) = id);

create policy profiles_update_own
on public.profiles
for update
to authenticated
using ((select auth.uid()) = id)
with check ((select auth.uid()) = id);

-- DECKS: CRUD limited to owner.
create policy decks_select_own
on public.decks
for select
to authenticated
using (
    (select auth.uid()) is not null
    and user_id = (select auth.uid())
);

create policy decks_insert_own
on public.decks
for insert
to authenticated
with check (
    (select auth.uid()) is not null
    and user_id = (select auth.uid())
);

create policy decks_update_own
on public.decks
for update
to authenticated
using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()));

create policy decks_delete_own
on public.decks
for delete
to authenticated
using (user_id = (select auth.uid()));

-- FLASHCARDS: ownership is inherited through the parent deck.
create policy flashcards_select_via_owned_deck
on public.flashcards
for select
to authenticated
using (
    exists (
        select 1
        from public.decks d
        where d.id = flashcards.deck_id
          and d.user_id = (select auth.uid())
    )
);

create policy flashcards_insert_via_owned_deck
on public.flashcards
for insert
to authenticated
with check (
    exists (
        select 1
        from public.decks d
        where d.id = flashcards.deck_id
          and d.user_id = (select auth.uid())
    )
);

create policy flashcards_update_via_owned_deck
on public.flashcards
for update
to authenticated
using (
    exists (
        select 1
        from public.decks d
        where d.id = flashcards.deck_id
          and d.user_id = (select auth.uid())
    )
)
with check (
    exists (
        select 1
        from public.decks d
        where d.id = flashcards.deck_id
          and d.user_id = (select auth.uid())
    )
);

create policy flashcards_delete_via_owned_deck
on public.flashcards
for delete
to authenticated
using (
    exists (
        select 1
        from public.decks d
        where d.id = flashcards.deck_id
          and d.user_id = (select auth.uid())
    )
);

-- REVIEW LOGS: read-only to clients, and only own rows.
create policy review_logs_select_own
on public.review_logs
for select
to authenticated
using (user_id = (select auth.uid()));
