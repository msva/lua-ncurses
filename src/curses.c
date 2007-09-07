#include <curses.h>
#include <lua.h>
#include <lauxlib.h>
#include <signal.h>
#include <stdlib.h>
#include <string.h>

#define REG_TABLE "luancurses"

typedef struct _pos {
    int x;
    int y;
} pos;

static int ncolors = 1, ncolor_pairs = 1;

/* necessary because atexit() expects a function that returns void, and gcc
 * whines otherwise */
static void _endwin(void)
{
    endwin();
}

static void init_colors(lua_State* L)
{
    lua_pushinteger(L, COLOR_BLACK);
    lua_setfield(L, -2, "black");
    lua_pushinteger(L, COLOR_RED);
    lua_setfield(L, -2, "red");
    lua_pushinteger(L, COLOR_GREEN);
    lua_setfield(L, -2, "green");
    lua_pushinteger(L, COLOR_YELLOW);
    lua_setfield(L, -2, "yellow");
    lua_pushinteger(L, COLOR_BLUE);
    lua_setfield(L, -2, "blue");
    lua_pushinteger(L, COLOR_MAGENTA);
    lua_setfield(L, -2, "magenta");
    lua_pushinteger(L, COLOR_CYAN);
    lua_setfield(L, -2, "cyan");
    lua_pushinteger(L, COLOR_WHITE);
    lua_setfield(L, -2, "white");

    ncolors = 8;
}

static pos get_pos(lua_State* L)
{
    pos ret;

    getyx(stdscr, ret.y, ret.x);

    lua_getfield(L, -1, "x");
    if (lua_isnumber(L, -1)) {
        ret.x = lua_tonumber(L, -1);
    }
    lua_pop(L, 1);

    lua_getfield(L, -1, "y");
    if (lua_isnumber(L, -1)) {
        ret.y = lua_tonumber(L, -1);
    }
    lua_pop(L, 1);

    return ret;
}

static int l_initscr(lua_State* L)
{
    lua_pushboolean(L, initscr() == OK);
    return 1;
}

static int l_start_color(lua_State* L)
{
    if (has_colors()) {
        lua_getfield(L, LUA_REGISTRYINDEX, REG_TABLE);
        lua_newtable(L);
        lua_setfield(L, -2, "color_pairs");
        lua_newtable(L);
        init_colors(L);
        lua_setfield(L, -2, "colors");
        lua_setfield(L, LUA_REGISTRYINDEX, REG_TABLE);
        lua_pushboolean(L, start_color() == OK);
    }
    else {
        lua_pushboolean(L, FALSE);
    }

    return 1;
}

static int l_setup_term(lua_State* L)
{
    int ret = 0;

    luaL_checktype(L, 1, LUA_TTABLE);

    lua_pushnil(L);
    while (lua_next(L, 1) != 0) {
        if (lua_isstring(L, -2)) {
            const char* str;

            str = lua_tostring(L, -2);
            /* XXX: this certainly needs expansion */
            if (!strcmp(str, "nl")) {
                ret += ((lua_toboolean(L, -1) ? nl() : nonl()) == OK);
            }
            else if (!strcmp(str, "cbreak")) {
                ret += ((lua_toboolean(L, -1) ? cbreak() : nocbreak()) == OK);
            }
            else if (!strcmp(str, "echo")) {
                ret += ((lua_toboolean(L, -1) ? echo() : noecho()) == OK);
            }
            else if (!strcmp(str, "keypad")) {
                ret += (keypad(stdscr, lua_toboolean(L, -1)) == OK);
            }
            else if (!strcmp(str, "scroll")) {
                ret += (scrollok(stdscr, lua_toboolean(L, -1)) == OK);
            }
            else {
                luaL_error(L, "Unknown or unimplemented terminal mode %s", str);
            }
        }
        lua_pop(L, 1);
    }

    lua_pushnumber(L, ret);
    return 1;
}

static int l_init_color(lua_State* L)
{
    /* test can_change_color here */
    return 0;
}

static int l_init_pair(lua_State* L)
{
    const char *name, *fg, *bg;
    int name_val, fg_val, bg_val;

    /* check the arguments, and get them */
    name = luaL_checklstring(L, 1, NULL);
    fg =   luaL_optlstring(L, 2, "white", NULL);
    bg =   luaL_optlstring(L, 3, "black", NULL);

    lua_getfield(L, LUA_REGISTRYINDEX, REG_TABLE);

    /* figure out which pair value to use */
    lua_getfield(L, -1, "color_pairs");
    lua_getfield(L, -1, name);
    if (lua_isnil(L, -1)) {
        /* if it was nil, we want to set a new value in the color_pairs table,
         * and we want to leave that C color_pair value on top of the stack
         * for consistency */
        lua_pop(L, 1);
        lua_pushinteger(L, ncolor_pairs++);
        lua_pushvalue(L, -1);
        lua_setfield(L, -3, name);
    }
    name_val = lua_tointeger(L, -1);
    lua_pop(L, 2);

    /* figure out which foreground value to use */
    lua_getfield(L, -1, "colors");
    lua_getfield(L, -1, fg);
    if (lua_isnil(L, -1)) {
        return luaL_error(L, "init_pair: Trying to use a non-existant foreground color");
    }
    fg_val = lua_tointeger(L, -1);
    lua_pop(L, 1);

    /* and background value */
    lua_getfield(L, -1, bg);
    if (lua_isnil(L, -1)) {
        return luaL_error(L, "init_pair: Trying to use a non-existant background color");
    }
    bg_val = lua_tointeger(L, -1);
    lua_pop(L, 3);

    lua_pushboolean(L, (init_pair(name_val, fg_val, bg_val) == OK));
    return 1;
}

static int l_getch(lua_State* L)
{
    int c;
    
    if (lua_istable(L, 1)) {
        pos p;

        p = get_pos(L);
        c = mvgetch(p.y, p.x);
    }
    else {
        c = getch();
    }
    if (c == ERR) {
        lua_pushboolean(L, 0);
        return 1;
    }

    switch (c) {
        case KEY_LEFT:
            lua_pushstring(L, "left");
        break;
        case KEY_RIGHT:
            lua_pushstring(L, "right");
        break;
        case KEY_UP:
            lua_pushstring(L, "up");
        break;
        case KEY_DOWN:
            lua_pushstring(L, "down");
        break;
        case KEY_HOME:
            lua_pushstring(L, "home");
        break;
        case KEY_END:
            lua_pushstring(L, "end");
        break;
        case KEY_BACKSPACE:
            lua_pushstring(L, "backspace");
        break;
        case KEY_ENTER:
            lua_pushstring(L, "enter");
        break;
        case KEY_NPAGE:
            lua_pushstring(L, "page down");
        break;
        case KEY_PPAGE:
            lua_pushstring(L, "page up");
        break;
        default:
            if (c >= KEY_F(1) && c <= KEY_F(64)) {
                lua_pushfstring(L, "F%d", c - KEY_F0);
            }
            else {
                char s[1];

                s[0] = c;
                lua_pushlstring(L, s, 1);
            }
        break;
    }

    return 1;
}

static int l_move(lua_State* L)
{
    if (lua_istable(L, 1)) {
        pos p;

        p = get_pos(L);
        lua_pushboolean(L, (move(p.y, p.x) == OK));
    }
    else {
        int x, y;

        y = luaL_checkinteger(L, 1);
        x = luaL_checkinteger(L, 2);

        lua_pushboolean(L, (move(y, x) == OK));
    }

    return 1;
}

static int l_addstr(lua_State* L)
{
    if (lua_istable(L, 1)) {
        pos p;
        size_t l;
        const char* str;

        p = get_pos(L);
        str = luaL_checklstring(L, 2, &l);
        if (l == 1) {
            mvaddch(p.y, p.x, *str);
        }
        else {
            mvaddstr(p.y, p.x, str);
        }
    }
    else {
        size_t l;
        const char* str;

        str = luaL_checklstring(L, 1, &l);
        if (l == 1) {
            addch(*str);
        }
        else {
            addstr(str);
        }
    }

    return 1;
}

static int l_refresh(lua_State* L)
{
    lua_pushboolean(L, (refresh() == OK));
    return 1;
}

static int l_getmaxyx(lua_State* L)
{
    int x, y;

    getmaxyx(stdscr, y, x);

    lua_pushnumber(L, y);
    lua_pushnumber(L, x);
    return 2;
}

static int l_getyx(lua_State* L)
{
    int x, y;

    getyx(stdscr, y, x);

    lua_pushnumber(L, y);
    lua_pushnumber(L, x);
    return 2;
}

static int l_colors(lua_State* L)
{
    lua_pushinteger(L, COLORS);
    return 1;
}

static int l_color_pairs(lua_State* L)
{
    lua_pushinteger(L, COLOR_PAIRS);
    return 1;
}

const luaL_Reg reg[] = {
    { "initscr", l_initscr },
    { "start_color", l_start_color },
    { "setup_term", l_setup_term },
    { "init_color", l_init_color },
    { "init_pair", l_init_pair },
    { "getch", l_getch },
    { "move", l_move },
    { "addstr", l_addstr },
    { "refresh", l_refresh },
    { "getmaxyx", l_getmaxyx },
    { "getyx", l_getyx },
    { "colors", l_colors },
    { "color_pairs", l_color_pairs },
    { NULL, NULL },
};

extern int luaopen_curses(lua_State* L)
{
    /* XXX: do we want to do this? how important is cleaning up? */
    signal(SIGTERM, exit);
    atexit(_endwin);

    lua_newtable(L);
    lua_setfield(L, LUA_REGISTRYINDEX, REG_TABLE);

    luaL_register(L, "curses", reg);

    return 1;
}
