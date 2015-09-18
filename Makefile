include .config

UNAME            ?= $(shell uname)
DESTDIR          ?= /
PKG_CONFIG       ?= pkg-config
INSTALL          ?= install
RM               ?= rm
LUA_IMPL         ?= lua
LUA_BIN          ?= $(LUA_IMPL)
LUA_CMODULE_DIR  ?= $(shell $(PKG_CONFIG) --variable INSTALL_CMOD $(LUA_IMPL))
LUA_CF           ?= $(shell $(PKG_CONFIG) --cflags $(LUA_IMPL))
CC               ?= cc

ifeq ($(UNAME), Linux)
OS_FLAGS         ?= -shared
endif
ifeq ($(UNAME), Darwin)
OS_FLAGS         ?= -bundle -undefined dynamic_lookup
endif

BIN               = src/curses.so
OBJ               = src/curses.o src/strings.o
INCLUDES          =
DEFINES           =
LIBS              = -lcurses
COMMONFLAGS       = -O2 -g -std=c99 -pipe -fPIC $(OS_FLAGS)
LF                = $(LIBS) $(COMMONFLAGS) $(LDFLAGS)
CF                = -c $(INCLUDES) $(DEFINES) $(COMMONFLAGS) $(LUA_CF) $(CFLAGS)

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

$(OBJ): $(HDR)

$(BIN): $(OBJ)
	$(CC) $(LF) $^ -o $@

%.o: %.c
	$(CC) $(CF) -o $@ $<

clean:
	$(RM) -f $(OBJ) $(BIN) test/*.so

dep:
	makedepend $(DEFINES) -Y $(SRC) > /dev/null 2>&1
	$(RM) -f Makefile.bak

test: all
	-ln -sf ../$(BIN) test/
	@echo "Test should be run from interactive shell."
	@echo "So, try to run:"
	@echo '$ cd test && $(LUA_BIN) rl.lua'
	@echo "and test, if it works."
	@echo "Test app can be closed by ^C."

install: all
	$(INSTALL) -d $(DESTDIR)$(LUA_CMODULE_DIR)
	$(INSTALL) $(BIN) $(DESTDIR)$(LUA_CMODULE_DIR)

uninstall: clean
	cd $(LUA_CMODULE_DIR);
	$(RM) -f $(BIN)

dist: $(VERSION).tar.gz

$(VERSION).tar.gz: $(SRC) $(TEST_FLS) $(OTHER_FILES)
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
