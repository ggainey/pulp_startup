\timing
update rpm_package set evr = (
  select ROW(coalesce(epoch::numeric,0),
             rpmver_array(version)::evr_array_item[],
             rpmver_array(release)::evr_array_item[])::evr_t
  );
