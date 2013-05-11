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

UNAME := $(shell uname)
DESTDIR := "/"
PKG_CONFIG := "pkg-config"
LUA_IMPL := "lua"
LUA_LIBDIR = ${DESTDIR}$(shell pkg-config --variable INSTALL_CMOD ${LUA_IMPL})
LUA_INC = $(shell pkg-config --variable INSTALL_INC ${LUA_IMPL})
LUA_LIBNAME := ${LUA_IMPL}

ifeq ($(LUA_IMPL), luajit)
LUA_LIBNAME := luajit-5.1
endif

ifeq ($(UNAME), Linux)
OS_FLAGS = -shared
endif
ifeq ($(UNAME), Darwin)
OS_FLAGS = -bundle -undefined dynamic_lookup
endif

BIN = src/curses.so
OBJ = src/curses.o src/strings.o
CC := "cc"
INCLUDES = -I$(LUA_INC)
DEFINES =
LIBS = -lcurses -l$(LUA_LIBNAME)
COMMONFLAGS = -O2 -g -std=c99 -pipe -fPIC $(OS_FLAGS)
INCFS = -c $(INCLUDES) $(DEFINES) $(COMMONFLAGS)
INLDFS = $(LIBS) $(COMMONFLAGS)

SRC = src/curses.c src/strings.c src/strings.h
TEST_LUAS = test/rl.lua \
            test/test.lua
TTT_TEST_DIR = tictactoe
TTT_TEST_LUAS = test/tictactoe/tictactoe.lua \
		test/tictactoe/tictactoe_board.lua \
		test/tictactoe/tictactoe_player.lua
OTHER_FILES = Makefile \
	      Make.config \
	      README \
	      LICENSE \
	      TODO
VERSION = "LuaNcurses-0.0.3"

build : $(BIN)

$(BIN) : $(OBJ)
	@$(call ext,"Library compiling and linking...")
	@$(CC) $(OBJ) $(INLDFS) $(LDFLAGS) -o $@
	@$(call inf,"Library compiling and linking is done!")

%.o : %.c
	@$(call ext,"Object files compliling in progress...")
	@$(CC) $(INCFS) $(CFLAGS) -o $@ $<
	@$(call inf,"Object files compliling is done!")

clean :
	@$(call wrn,"Cleaning...")
	@rm -f $(OBJ) $(BIN)
	@$(call inf,"Cleaning is done!")

dep :
	@$(call ext,"Making depends...")
	@makedepend $(DEFINES) -Y $(SRC) > /dev/null 2>&1
	@rm -f Makefile.bak
	@$(call inf,"Making depends is done!")

install :
	@$(call ext,"Installing...")
	@mkdir -p $(LUA_LIBDIR)
	@cp -f $(BIN) $(LUA_LIBDIR)
	@$(call inf,"Installing is done!")

uninstall : clean
	@$(call wrn,"Uninstalling...")
	@cd $(LUA_LIBDIR);
	@rm -f $(BIN)
	@$(call inf,"Uninstalling is done!")

dist : $(VERSION).tar.gz

$(VERSION).tar.gz : $(SRC) $(TEST_LUAS) $(OTHER_FILES)
	@$(call ext,"Creating $(VERSION).tar.gz...")
	@mkdir $(VERSION)
	@mkdir $(VERSION)/src
	@cp $(SRC) $(VERSION)/src
	@mkdir $(VERSION)/test
	@cp $(TEST_LUAS) $(VERSION)/test
	@mkdir $(VERSION)/test/$(TTT_TEST_DIR)
	@cp $(TTT_TEST_LUAS) $(VERSION)/test/$(TTT_TEST_DIR)
	@cp $(OTHER_FILES) $(VERSION)
	@tar czf $(VERSION).tar.gz $(VERSION)
	@rm -rf $(VERSION)
	@$(call inf,"Creating is done!")

# DO NOT DELETE

src/curses.o: src/strings.h
src/strings.o: src/strings.h
