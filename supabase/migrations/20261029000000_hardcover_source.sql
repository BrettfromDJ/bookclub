-- Allow books found through Hardcover search.
alter table public.books drop constraint books_source_check;
alter table public.books add constraint books_source_check check (source in ('hardcover', 'google', 'openlibrary', 'manual'));
