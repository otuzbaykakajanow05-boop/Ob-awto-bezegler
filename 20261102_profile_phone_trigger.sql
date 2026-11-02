-- Update the signup trigger to copy the phone number entered in the app.
-- Existing profiles and administrator role are not changed.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, phone)
  values (
    new.id,
    coalesce(new.phone, new.raw_user_meta_data ->> 'phone')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;
