include .config
# Some functions for candiness-looking
err =                                           \
        @echo -e "\e[1;31m*\e[0m $(1)\e[0m";    \
        @exit 1;
inf =                                           \
        @echo -e "\e[1;32m*\e[0m $(1)\e[0m";
wrn =                                           \
        @echo -e "\e[1;33m*\e[0m $(1)\e[0m";
ext =                                           \
        @echo -e "\e[1;35m*\e[0m $(1)\e[0m";

UNAME            ?= $(shell uname)
DESTDIR          ?= /
PKG_CONFIG       ?= pkg-config
INSTALL          ?= install
RM               ?= rm
LUA_IMPL         ?= lua
LUA_BIN          ?= $(LUA_IMPL)
LUA_CMODULE_DIR  ?= $(shell $(PKG_CONFIG) --variable INSTALL_CMOD $(LUA_IMPL))
LIBDIR           ?= $(shell $(PKG_CONFIG) --variable libdir $(LUA_IMPL))
LUA_INC          ?= $(shell $(PKG_CONFIG) --variable INSTALL_INC $(LUA_IMPL))
CC               ?= cc

ifeq ($(UNAME), Linux)
OS_FLAGS         ?= -shared
endif
ifeq ($(UNAME), Darwin)
OS_FLAGS         ?= -bundle -undefined dynamic_lookup
endif

BIN               = src/curses.so
OBJ               = src/curses.o src/strings.o
INCLUDES          = -I$(LUA_INC)
DEFINES           =
LIBS              = -L$(LIBDIR) -lcurses
COMMONFLAGS       = -O2 -g -std=c99 -pipe -fPIC $(OS_FLAGS)
LF                = $(LIBS) $(COMMONFLAGS) $(LDFLAGS)
CF                = -c $(INCLUDES) $(DEFINES) $(COMMONFLAGS) $(CFLAGS)

SRC               = src/curses.c src/strings.c
HDR               = src/strings.h
TEST_FLS          = test/rl.lua \
                    test/test.lua
TTT_TEST_DIR      = tictactoe
TTT_TEST_FLS      = test/tictactoe/tictactoe.lua \
                    test/tictactoe/tictactoe_board.lua \
                    test/tictactoe/tictactoe_player.lua
OTHER_FILES       = Makefile \
	            .config \
	            README \
	            LICENSE \
	            TODO
VERSION           = "LuaNcurses-0.0.3"

all: $(BIN)

$(BIN): $(OBJ)
	@$(call ext,"Library compiling and linking...")
	@$(CC) $(LF) $^ -o $@
	@$(call inf,"Library compiling and linking is done!")

%.o: %.c
	@$(call ext,"Object files compliling in progress...")
	@$(CC) $(CF) -o $@ $<
	@$(call inf,"Object files compliling is done!")

clean:
	@$(call wrn,"Cleaning...")
	@$(RM) -f $(OBJ) $(BIN) test/*.so
	@$(call inf,"Cleaning is done!")

dep:
	@$(call ext,"Making depends...")
	@makedepend $(DEFINES) -Y $(SRC) > /dev/null 2>&1
	@$(RM) -f Makefile.bak
	@$(call inf,"Making depends is done!")

test: all
	@$(call wrn,"Testing...")
	-@ln -sf ../$(BIN) test/
	@$(call wrn,"Test should be run from interactive shell.")
	@$(call ext,"So try to run:")
	@$(call wrn,"$ cd test \&\& $(LUA_BIN) rl.lua")
	@$(call ext,"and test if it works.")
	@$(call ext,"Test app can be closed by ^C.")
	@$(call inf,"Testing is done!")

install: all
	@$(call ext,"Installing...")
	@$(INSTALL) -d $(DESTDIR)$(LUA_CMODULE_DIR)
	@$(INSTALL) $(BIN) $(DESTDIR)$(LUA_CMODULE_DIR)
	@$(call inf,"Installing is done!")

uninstall: clean
	@$(call wrn,"Uninstalling...")
	@cd $(LUA_CMODULE_DIR);
	@$(RM) -f $(BIN)
	@$(call inf,"Uninstalling is done!")

dist: $(VERSION).tar.gz

$(VERSION).tar.gz: $(SRC) $(TEST_FLS) $(OTHER_FILES)
	@$(call ext,"Creating $(VERSION).tar.gz...")
	@mkdir $(VERSION)
	@mkdir $(VERSION)/src
	@cp $(SRC) $(HDR) $(VERSION)/src
	@mkdir $(VERSION)/test
	@cp $(TEST_FLS) $(VERSION)/test
	@mkdir $(VERSION)/test/$(TTT_TEST_DIR)
	@cp $(TTT_TEST_FLS) $(VERSION)/test/$(TTT_TEST_DIR)
	@cp $(OTHER_FILES) $(VERSION)
	@tar -czf $(VERSION).tar.gz $(VERSION)
	@$(RM) -rf $(VERSION)
	@$(call inf,"Creating is done!")

# DO NOT DELETE

src/curses.o: src/strings.h
src/strings.o: src/strings.h
