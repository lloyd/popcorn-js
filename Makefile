PREFIX = .
BUILD_DIR = ${PREFIX}/build
DIST_DIR = ${PREFIX}/dist
PLUGINS_DIR = ${PREFIX}/plugins
PLUGINS_DIST_DIR = ${DIST_DIR}/plugins
PARSERS_DIR = ${PREFIX}/parsers
PARSERS_DIST_DIR = ${DIST_DIR}/parsers
PLAYERS_DIR = ${PREFIX}/players
PLAYERS_DIST_DIR = ${DIST_DIR}/players
EFFECTS_DIR = $(PREFIX)/effects
EFFECTS_DIST_DIR = $(DIST_DIR)/effects
DIST_DIRS = ${DIST_DIR} ${PLUGINS_DIST_DIR} ${PARSERS_DIST_DIR} ${PLAYERS_DIST_DIR} ${EFFECTS_DIST_DIR}

# Version number used in naming release files. Defaults to git commit sha.
VERSION ?= $(shell git show -s --pretty=format:%h)

RHINO ?= java -jar ${BUILD_DIR}/js.jar

CLOSURE_COMPILER = ${BUILD_DIR}/google-compiler-20100917.jar
compile = @@${MINJAR} $(1) \
	                    --compilation_level SIMPLE_OPTIMIZATIONS \
	                    --js_output_file $(2)

# minify
MINJAR ?= java -jar ${CLOSURE_COMPILER}

# source
POPCORN_SRC = ${PREFIX}/popcorn.js

# distribution files
POPCORN_DIST = ${DIST_DIR}/popcorn.js
POPCORN_MIN = ${DIST_DIR}/popcorn.min.js

# plugins
PLUGINS_DIST = ${DIST_DIR}/popcorn.plugins.js
PLUGINS_MIN = ${DIST_DIR}/popcorn.plugins.min.js

# plugins
PARSERS_DIST = ${DIST_DIR}/popcorn.parsers.js
PARSERS_MIN = ${DIST_DIR}/popcorn.parsers.min.js

# players
PLAYERS_DIST = ${DIST_DIR}/popcorn.players.js
PLAYERS_MIN = ${DIST_DIR}/popcorn.players.min.js

# effects
EFFECTS_DIST = $(DIST_DIR)/popcorn.effects.js
EFFECTS_MIN = $(DIST_DIR)/popcorn.effects.min.js

# json "manifest", used by configurator
MANIFEST_DIST = $(DIST_DIR)/manifest.json

# Grab all popcorn.<plugin-name>.js files from plugins dir
PLUGINS_SRC := $(filter-out %unit.js, $(shell find ${PLUGINS_DIR} -name 'popcorn.*.js' -print))

# Grab all popcorn.<plugin-name>.js files from parsers dir
PARSERS_SRC := $(filter-out %unit.js, $(shell find ${PARSERS_DIR} -name 'popcorn.*.js' -print))

# Grab all popcorn.<player-name>.js files from players dir
PLAYERS_SRC := $(filter-out %unit.js, $(shell find ${PLAYERS_DIR} -name 'popcorn.*.js' -print))

# Grab all popcorn.<effect-name>.js files from players dir
EFFECTS_SRC := $(filter-out %unit.js, $(shell find $(EFFECTS_DIR) -name 'popcorn.*.js' -print))

# INDividual files for all parsers, players, plugins, and effects.  By outputting
# these, we allow for dynamic creation of a custom popcorn bundle
PARSERS_IND_DIST := $(addprefix ${PARSERS_DIST_DIR}/, $(notdir ${PARSERS_SRC}))
PLAYERS_IND_DIST := $(addprefix ${PLAYERS_DIST_DIR}/, $(notdir ${PLAYERS_SRC}))
PLUGINS_IND_DIST := $(addprefix ${PLUGINS_DIST_DIR}/, $(notdir ${PLUGINS_SRC}))
EFFECTS_IND_DIST := $(addprefix ${EFFECTS_DIST_DIR}/, $(notdir ${EFFECTS_SRC}))

# Grab all popcorn.<player-name>.unit.js files from plugins dir
PLUGINS_UNIT := $(shell find ${PLUGINS_DIR} -name 'popcorn.*.unit.js' -print)

# Grab all popcorn.<player-name>.unit.js files from parsers dir
PARSERS_UNIT := $(shell find ${PARSERS_DIR} -name 'popcorn.*.unit.js' -print)

# Grab all popcorn.<player-name>.unit.js files from players dir
PLAYERS_UNIT := $(shell find ${PLAYERS_DIR} -name 'popcorn.*.unit.js' -print)

# Grab all popcorn.<effects>.unit.js files from players dir
EFFECTS_UNIT := $(shell find $(EFFECTS_DIR) -name 'popcorn.*.unit.js' -print)

# popcorn + plugins
POPCORN_COMPLETE_LIST := --js ${POPCORN_SRC} \
                         $(shell for js in ${PLUGINS_SRC} ; do echo --js $$js ; done) \
                         $(shell for js in ${PARSERS_SRC} ; do echo --js $$js ; done) \
                         $(shell for js in ${PLAYERS_SRC} ; do echo --js $$js ; done)
POPCORN_COMPLETE_DIST = ${DIST_DIR}/popcorn-complete.js
POPCORN_COMPLETE_MIN = ${DIST_DIR}/popcorn-complete.min.js

# Create a versioned license header for js files we ship: arg1=source arg2=dest
add_license = cat ${PREFIX}/LICENSE_HEADER | sed -e 's/@VERSION/${VERSION}/' > $(2) ; \
	                    cat $(1) >> $(2)

# Run the file through jslint
run_lint = @@$(RHINO) build/jslint-check.js $(1)

all: setup popcorn plugins parsers players effects complete min configurator
	@@echo "Popcorn build complete.  To create a testing mirror, run: make testing."

check: lint lint-plugins lint-parsers lint-players lint-effects

${DIST_DIRS}:
	@@mkdir -p $@

popcorn: ${POPCORN_DIST}

${POPCORN_DIST}: ${POPCORN_SRC} | ${DIST_DIR}
	@@echo "Building" ${POPCORN_DIST}
	@@$(call add_license, $(POPCORN_SRC), $(POPCORN_DIST))

min: ${POPCORN_MIN} ${PLUGINS_MIN} ${PARSERS_MIN} ${PLAYERS_MIN} $(EFFECTS_MIN) ${POPCORN_COMPLETE_MIN}

${POPCORN_MIN}: ${POPCORN_DIST}
	@@echo "Building" ${POPCORN_MIN}
	@@$(call compile, --js ${POPCORN_DIST}, ${POPCORN_MIN}.tmp)
	@@$(call add_license, ${POPCORN_MIN}.tmp, ${POPCORN_MIN})
	@@rm ${POPCORN_MIN}.tmp

${POPCORN_COMPLETE_MIN}: update ${POPCORN_SRC} ${PLUGINS_SRC} ${PARSERS_SRC} $(EFFECTS_SRC) ${DIST_DIR}
	@@echo "Building" ${POPCORN_COMPLETE_MIN}
	@@$(call compile, ${POPCORN_COMPLETE_LIST}, ${POPCORN_COMPLETE_MIN}.tmp)
	@@$(call add_license, ${POPCORN_COMPLETE_MIN}.tmp, ${POPCORN_COMPLETE_MIN})
	@@rm ${POPCORN_COMPLETE_MIN}.tmp

plugins: ${PLUGINS_DIST}

${PLUGINS_MIN}: ${PLUGINS_DIST}
	@@echo "Building" ${PLUGINS_MIN}
	@@$(call compile, $(shell for js in ${PLUGINS_SRC} ; do echo --js $$js ; done), ${PLUGINS_MIN})

${PLUGINS_DIST}: ${PLUGINS_SRC} ${DIST_DIR}
	@@echo "Building ${PLUGINS_DIST}"
	@@cat ${PLUGINS_SRC} > ${PLUGINS_DIST}

parsers: ${PARSERS_DIST}

${PARSERS_MIN}: ${PARSERS_DIST}
	@@echo "Building" ${PARSERS_MIN}
	@@$(call compile, $(shell for js in ${PARSERS_SRC} ; do echo --js $$js ; done), ${PARSERS_MIN})

${PARSERS_DIST}: ${PARSERS_SRC} ${DIST_DIR}
	@@echo "Building ${PARSERS_DIST}"
	@@cat ${PARSERS_SRC} > ${PARSERS_DIST}

players: ${PLAYERS_DIST}

${PLAYERS_MIN}: ${PLAYERS_DIST}
	@@echo "Building" ${PLAYERS_MIN}
	@@$(call compile, $(shell for js in ${PLAYERS_SRC} ; do echo --js $$js ; done), ${PLAYERS_MIN})

${PLAYERS_DIST}: ${PLAYERS_SRC} ${DIST_DIR}
	@@echo "Building ${PLAYERS_DIST}"
	@@cat ${PLAYERS_SRC} > ${PLAYERS_DIST}

effects: $(EFFECTS_DIST)

$(EFFECTS_MIN): $(EFFECTS_DIST)
	@@echo "Building" $(EFFECTS_MIN)
	@@$(call compile, $(shell for js in $(EFFECTS_SRC) ; do echo --js $$js ; done), $(EFFECTS_MIN))

$(EFFECTS_DIST): $(EFFECTS_SRC) $(DIST_DIR)
	@@echo "Building $(EFFECTS_DIST)"
	@@cat $(EFFECTS_SRC) > $(EFFECTS_DIST)

complete: update ${POPCORN_SRC} ${PARSERS_SRC} ${PLUGINS_SRC} ${PLAYERS_SRC} $(EFFECTS_SRC) ${DIST_DIR}
	@@echo "Building popcorn + plugins + parsers + players + effects..."
	@@cat ${POPCORN_SRC} ${PLUGINS_SRC} ${PARSERS_SRC} ${PLAYERS_SRC} $(EFFECTS_SRC) > ${POPCORN_COMPLETE_DIST}.tmp
	@@$(call add_license, ${POPCORN_COMPLETE_DIST}.tmp, ${POPCORN_COMPLETE_DIST})
	@@rm ${POPCORN_COMPLETE_DIST}.tmp


# The 'configurator' target outputs individual minified files along with a JSON manifest.
# This distribution output is what the web based popcorn.js configurator uses as
# input to dynamically assemble a custom library on the end user's browser
${PARSERS_IND_DIST} : ${PARSERS_SRC}
	@@echo "Building $@"
	@@$(call compile, --js $(filter %$(notdir $@), ${PARSERS_SRC}), $@)

${PLUGINS_IND_DIST} : ${PLUGINS_SRC}
	@@echo "Building $@"
	@@$(call compile, --js $(filter %$(notdir $@), ${PLUGINS_SRC}), $@)

${PLAYERS_IND_DIST} : ${PLAYERS_SRC}
	@@echo "Building $@"
	@@$(call compile, --js $(filter %$(notdir $@), ${PLAYERS_SRC}), $@)

${EFFECTS_IND_DIST} : ${EFFECTS_SRC}
	@@echo "Building $@"
	@@$(call compile, --js $(filter %$(notdir $@), ${EFFECTS_SRC}), $@)

# Write the JSON manifest.json from a Makefile. 
comma:= ,
empty:=
space:= $(empty) $(empty)
json_array = $(subst $(space),$(comma),$(addprefix \", $(addsuffix \", $(notdir $(1)))))

${MANIFEST_DIST}: ${EFFECTS_IND_DIST} ${PLAYERS_IND_DIST} ${PLUGINS_IND_DIST} ${PARSERS_IND_DIST}
	@@echo "{" > ${MANIFEST_DIST}	
	@@echo '  "plugins": [' $(call json_array, ${PLUGINS_IND_DIST}) '],'>> ${MANIFEST_DIST}	
	@@echo '  "effects": [' $(call json_array, ${EFFECTS_IND_DIST}) '],'>> ${MANIFEST_DIST}	
	@@echo '  "players": [' $(call json_array, ${PLAYERS_IND_DIST}) '],'>> ${MANIFEST_DIST}	
	@@echo '  "parsers": [' $(call json_array, ${PARSERS_IND_DIST}) ']'>> ${MANIFEST_DIST}	
	@@echo "}" >> ${MANIFEST_DIST}	

configurator: update ${DIST_DIRS} ${PARSERS_IND_DIST} ${PLUGINS_IND_DIST} ${PLAYERS_IND_DIST} ${EFFECTS_IND_DIST} ${MANIFEST_DIST}
	@@echo "Built individual files for configurator"

lint:
	@@echo "Checking Popcorn against JSLint..."
	@@$(call run_lint,popcorn.js)

lint-plugins:
	@@echo "Checking all plugins against JSLint..."
	@@$(call run_lint,$(PLUGINS_SRC))

lint-parsers:
	@@echo "Checking all parsers against JSLint..."
	@@$(call run_lint,$(PARSERS_SRC))

lint-players:
	@@echo "Checking all players against JSLint..."
	@@$(call run_lint,$(PLAYERS_SRC))

lint-effects:
	@@echo "Checking all effects against JSLint..."
	@@$(call run_lint,$(EFFECTS_SRC))

lint-plugin-tests:
	@@echo "Checking plugin unit tests against JSLint..."
	@@$(call run_lint,$(PLUGINS_UNIT))

lint-parser-tests:
	@@echo "Checking parser unit tests against JSLint..."
	@@$(call run_lint,$(PARSERS_UNIT))

lint-effects-tests:
	@@echo "Checking effectsr unit tests against JSLint..."
	@@$(call run_lint,$(EFFECTS_UNIT))

lint-player-tests:
	@@echo "Checking player unit tests against JSLint..."
	@@$(call run_lint,$(PLAYERS_UNIT))

lint-unit-tests: lint-plugin-tests lint-parser-tests lint-player-tests lint-effects-tests
	@@echo "completed"

# Create a mirror copy of the tree in dist/ using popcorn-complete.js
# in place of popcorn.js.
TESTING_MIRROR := ${DIST_DIR}/testing-mirror

# Prefer plugin code in popcorn-complete.js but don't overrwrite *unit.js files
overwrite_js = @@for js in $$(find ${1} \( -name "*.js" -a \! -name "*.unit.js" \)) ; \
                 do echo '/* Stub, see popcorn.js instead */' > $$js ; \
                 done

testing: complete
	@@echo "Building testing-mirror in ${TESTING_MIRROR}"
	@@mkdir -p ${TESTING_MIRROR}
	@@find ${PREFIX} \( -name '.git' -o -name 'dist' \) -prune -o -print | cpio -pd --quiet ${TESTING_MIRROR}
# Remove unneeded files for testing, so it's clear this isn't the tree
	@@rm -fr ${TESTING_MIRROR}/AUTHORS ${TESTING_MIRROR}/LICENSE ${TESTING_MIRROR}/LICENSE_HEADER \
           ${TESTING_MIRROR}/Makefile ${TESTING_MIRROR}/readme.md
	@@touch "${TESTING_MIRROR}/THIS IS A TESTING MIRROR -- READ-ONLY"
	$(call overwrite_js, ${TESTING_MIRROR}/plugins)
	$(call overwrite_js, ${TESTING_MIRROR}/players)
	$(call overwrite_js, ${TESTING_MIRROR}/parsers)
	$(call overwrite_js, ${TESTING_MIRROR}/effects)
	@@cp ${POPCORN_COMPLETE_DIST} ${TESTING_MIRROR}/popcorn.js

clean:
	@@echo "Removing Distribution directory:" ${DIST_DIR}
	@@rm -rf ${DIST_DIR}

# Setup any git submodules we need
SEQUENCE_SRC = ${PLAYERS_DIR}/sequence/popcorn.sequence.js

setup: ${SEQUENCE_SRC} update

update:
	@@echo "Updating submodules..."
	@@git submodule update
	@@cd  players/sequence; git pull origin master

${SEQUENCE_SRC}:
	@@echo "Setting-up submodules..."
	@@git submodule init
