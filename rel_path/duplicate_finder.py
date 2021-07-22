#!/usr/bin/env python

import collections
import itertools
import os
import os.path

import createrepo_c as cr

REPO_PATH = "repos/rhel8-appstream/"

primary_xml_path   = None
filelists_xml_path = None
other_xml_path     = None

repomd = cr.Repomd(os.path.join(REPO_PATH, "repodata/repomd.xml"))

def warningcb(warning_type, message):
    print("PARSER WARNING: %s" % message)
    return True

repomd2 = cr.Repomd()
cr.xml_parse_repomd(os.path.join(REPO_PATH, "repodata/repomd.xml"),
                                 repomd2, warningcb)

for record in repomd.records:
    if record.type == "primary":
        primary_xml_path = record.location_href
    elif record.type == "filelists":
        filelists_xml_path = record.location_href
    elif record.type == "other":
        other_xml_path = record.location_href

seen_packages = collections.defaultdict(list)

def pkgcb(pkg):
    seen_packages[pkg.pkgId].append(pkg)

def newpkgcb(pkgId, name, arch):
    pkgs = seen_packages.get(pkgId, None)
    if pkgs:
        return pkgs[-1]
    else:
        return None


cr.xml_parse_primary(os.path.join(REPO_PATH, primary_xml_path),
                     pkgcb=pkgcb,
                     do_files=False,
                     warningcb=warningcb)

cr.xml_parse_filelists(os.path.join(REPO_PATH, filelists_xml_path),
                       newpkgcb=newpkgcb,
                       warningcb=warningcb)

cr.xml_parse_other(os.path.join(REPO_PATH, other_xml_path),
                   newpkgcb=newpkgcb,
                   warningcb=warningcb)


duplicate_packages = {pkgid: pkgs for pkgid, pkgs in seen_packages.items() if len(pkgs) > 1}

num_unique_packages = len(seen_packages)
num_package_entries = sum([len(pkgs) for pkgs in seen_packages.values()])
num_duplicate_packages = len(duplicate_packages)

assert num_duplicate_packages == (num_package_entries - num_unique_packages)

print()
print("Summary")
print("==========")
print()
print("Total package entries: {}".format(num_package_entries))
print("Total unique packages: {}".format(num_unique_packages))
print("Total packages with duplicates: {}".format(num_duplicate_packages))
print()
print("Duplicates")
print("==========")
print()

for pkgid, pkgs in duplicate_packages.items():
    print("{} ({}) -- {} packages".format(pkgs[0].nevra(), pkgid, len(pkgs)))

print()
print("Details")
print("=======")
print()


def all_equal(iterable):
    g = itertools.groupby(iterable)
    return next(g, True) and not next(g, False)


field_names = [
    "name",
    "pkgId",
    "checksum_type",
    "arch",
    "version",
    "epoch",
    "release",
    "summary",
    "description",
    "url",
    "time_file",
    "time_build",
    "rpm_license",
    "rpm_vendor",
    "rpm_group",
    "rpm_buildhost",
    "rpm_sourcerpm",
    "rpm_header_start",
    "rpm_header_end",
    "rpm_packager",
    "size_package",
    "size_installed",
    "size_archive",
    "location_href",
    "location_base",
    "requires",
    "provides",
    "conflicts",
    "obsoletes",
    "files",
    "changelogs",
]

for pkgid, pkgs in duplicate_packages.items():
    print("Package {} ({})".format(pkgs[0].nevra(), pkgid))
    print("-----------------------------")

    for field_name in field_names:
        field_values = [getattr(pkg, field_name) for pkg in pkgs]
        if not all_equal(field_values):
            if field_name not in ("files", "changelogs"):
                print("Packages have different values for '{}' {}".format(field_name, field_values))
            else:
                print("Packages have different values for '{}'".format(field_name))

    print()
