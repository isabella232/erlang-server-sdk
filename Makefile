PROJECT = eld
PROJECT_DESCRIPTION = Erlang LaunchDarkly SDK Client
PROJECT_VERSION = 0.1.0

# Dependencies

LOCAL_DEPS = inets crypto asn1 public_key ssl

DEPS = shotgun jsx semver lru
dep_shotgun = git https://github.com/inaka/shotgun master
dep_jsx = git https://github.com/talentdeficit/jsx v2.9.0
dep_semver = git https://github.com/nebularis/semver master
dep_lru = git https://github.com/barrel-db/erlang-lru 1.3.1

DOC_DEPS = edown
EDOC_OPTS += '{doclet,edown_doclet}'

# Standard targets

include erlang.mk
