-- -----------------------------------------------------
-- evr type
-- represents version and release as arrays of parsed components
-- of proper type (numeric or varchar)
-- this allow us to use standard array operation for = > <
-- and most importantly sorting
--
-- In evt_t, version and release are arrays of evr_array_items
-- example: version 1:4.5.6-20.fc30 would be represented as
--  epoch = 1
--  version = [ (4,), (5,), (6,), (0, 'beta') ]
--  release = [ (20,), (0, 'fc'), (30,) ]
--
-- To experiment with different EVRs, use SQL like the following to generate the type:
-- select ROW(<epoch>, rpm_verarry(<version-str>), rpmver_array(<release-str>);
-- select ROW(1,       rpm_verarry('2.3.11'),      rpmver_array('6.fc31');
-- -----------------------------------------------------

-- a tuple that has an integer and/or a string representation
create type evr_array_item as (
        n       NUMERIC,
        s       TEXT
);

-- an epoch/version/release (evr) type
create type evr_t as (
        epoch TEXT,
        version evr_array_item[],
        release evr_array_item[]
);

ALTER TABLE rpm_package ADD COLUMN evr evr_t;

-- -----------------------------------------------------
-- isdigit, isalpha, isalphanum, and rpmver_array are
-- utility functions that let us create evr_t's from
-- existing e/v/r rows - used in update/insert triggers
-- on rpm_package
-- -----------------------------------------------------
create or replace function isdigit(ch CHAR)
    RETURNS BOOLEAN as $$
    BEGIN
        if ascii(ch) between ascii('0') and ascii('9')
        then
            return TRUE;
        end if;
        return FALSE;
    END ;
$$ language 'plpgsql';


create or replace FUNCTION isalpha(ch CHAR)
    RETURNS BOOLEAN as $$
    BEGIN
        if ascii(ch) between ascii('a') and ascii('z') or
            ascii(ch) between ascii('A') and ascii('Z')
        then
            return TRUE;
        end if;
        return FALSE;
    END;
$$ language 'plpgsql';


create or replace FUNCTION isalphanum(ch CHAR)
RETURNS BOOLEAN as $$
BEGIN
    if ascii(ch) between ascii('a') and ascii('z') or
        ascii(ch) between ascii('A') and ascii('Z') or
        ascii(ch) between ascii('0') and ascii('9')
    then
        return TRUE;
    end if;
    return FALSE;
END;
$$ language 'plpgsql';

create or replace FUNCTION empty(t TEXT)
RETURNS BOOLEAN as $$
BEGIN
    return t ~ '^[[:space:]]*$';
END;
$$ language 'plpgsql';

create or replace FUNCTION rpmver_array (string1 IN VARCHAR)
RETURNS evr_array_item[] as $$
declare
    str1 VARCHAR := string1;
    digits VARCHAR(10) := '0123456789';
    lc_alpha VARCHAR(27) := 'abcdefghijklmnopqrstuvwxyz';
    uc_alpha VARCHAR(27) := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    alpha VARCHAR(54) := lc_alpha || uc_alpha;
    one VARCHAR;
    isnum BOOLEAN;
    ver_array evr_array_item[] := ARRAY[]::evr_array_item[];
BEGIN
    if str1 is NULL
    then
        RAISE EXCEPTION 'VALUE_ERROR.';
    end if;

    one := str1;
    <<segment_loop>>
    while one <> ''
    loop
        declare
            segm1 VARCHAR;
            segm1_n NUMERIC := 0;
        begin
            -- Throw out all non-alphanum characters
            while one <> '' and not isalphanum(one)
            loop
                one := substr(one, 2);
            end loop;
            str1 := one;
            if str1 <> '' and isdigit(str1)
            then
                str1 := ltrim(str1, digits);
                isnum := true;
            else
                str1 := ltrim(str1, alpha);
                isnum := false;
            end if;
            if str1 <> ''
            then segm1 := substr(one, 1, length(one) - length(str1));
            else segm1 := one;
            end if;

            if segm1 = '' then return ver_array; end if; /* arbitrary */
            if isnum
            then
                segm1 := ltrim(segm1, '0');
                if segm1 <> '' then segm1_n := segm1::numeric; end if;
                segm1 := NULL;
            else
            end if;
            ver_array := array_append(ver_array, (segm1_n, segm1)::evr_array_item);
            one := str1;
        end;
    end loop segment_loop;

    return ver_array;
END ;
$$ language 'plpgsql';

-- This function creates an evr_t entry for an existing rpm_package row
CREATE FUNCTION evr_trigger() RETURNS trigger AS $$
  BEGIN
    NEW.evr = ROW(NEW.epoch, rpmver_array(NEW.version)::evr_array_item[], rpmver_array(NEW.release)::evr_array_item[])::evr_t;
    RETURN NEW;
  END;
$$ language 'plpgsql';

-- create evr_t on insert, so it matches the provided E/V/R cols
CREATE TRIGGER evr_insert_trigger
  BEFORE INSERT
  ON rpm_package
  FOR EACH ROW
  EXECUTE PROCEDURE evr_trigger();

-- create evr_t on update, so it continues to match the provided E/V/R cols,
-- but only if Something Changed
CREATE TRIGGER evr_update_trigger
  BEFORE UPDATE OF epoch, version, release
  ON rpm_package
  FOR EACH ROW
  WHEN (
    OLD.epoch IS DISTINCT FROM NEW.epoch OR
    OLD.version IS DISTINCT FROM NEW.version OR
    OLD.release IS DISTINCT FROM NEW.release
  )
  EXECUTE PROCEDURE evr_trigger();
