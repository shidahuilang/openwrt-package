/*
 * Copyright (C) 2002 Roman Zippel <zippel@linux-m68k.org>
 * Released under the terms of the GNU GPL v2.0.
 *
 * Introduced single menu mode (show all sub-menus in one large tree).
 * 2002-11-06 Petr Baudis <pasky@ucw.cz>
 *
 * Directly use liblxdialog library routines.
 * 2002-11-14 Petr Baudis <pasky@ucw.cz>
 */

#include <sys/ioctl.h>
#include <sys/wait.h>
#include <sys/termios.h>
#include <ctype.h>
#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <signal.h>
#include <stdarg.h>
#include <stdlib.h>
#include <string.h>
#include <termios.h>
#include <unistd.h>

#include "lxdialog/dialog.h"

#define LKC_DIRECT_LINK
#include "lkc.h"

static char menu_backtitle[128];
static const char mconf_readme[] =
"Overview\n"
"--------\n"
"Some features may be built directly into axTLS.  Some features\n"
"may be completely removed altogether.  There are also certain\n"
"parameters which are not really features, but must be\n"
"entered in as decimal or hexadecimal numbers or possibly text.\n"
"\n"
"Menu items beginning with [*] or [ ] represent features\n"
"configured to be built in or removed respectively.\n"
"\n"
"To change any of these features, highlight it with the cursor\n"
"keys and press <Y> to build it in or <N> to removed it.\n"
"You may also press the <Space Bar> to cycle\n"
"through the available options (ie. Y->N->Y).\n"
"\n"
"Some additional keyboard hints:\n"
"\n"
"Menus\n"
"----------\n"
"o  Use the Up/Down arrow keys (cursor keys) to highlight the item\n"
"   you wish to change or submenu wish to select and press <Enter>.\n"
"   Submenus are designated by \"--->\".\n"
"\n"
"   Shortcut: Press the option's highlighted letter (hotkey).\n"
"             Pressing a hotkey more than once will sequence\n"
"             through all visible items which use that hotkey.\n"
"\n"
"   You may also use the <PAGE UP> and <PAGE DOWN> keys to scroll\n"
"   unseen options into view.\n"
"\n"
"o  To exit a menu use the cursor keys to highlight the <Exit> button\n"
"   and press <ENTER>.\n"
"\n"
"   Shortcut: Press <ESC><ESC> or <E> or <X> if there is no hotkey\n"
"             using those letters.  You may press a single <ESC>, but\n"
"             there is a delayed response which you may find annoying.\n"
"\n"
"   Also, the <TAB> and cursor keys will cycle between <Select>,\n"
"   <Exit> and <Help>\n"
"\n"
"o  To get help with an item, use the cursor keys to highlight <Help>\n"
"   and Press <ENTER>.\n"
"\n"
"   Shortcut: Press <H> or <?>.\n"
"\n"
"\n"
"Radiolists  (Choice lists)\n"
"-----------\n"
"o  Use the cursor keys to select the option you wish to set and press\n"
"   <S> or the <SPACE BAR>.\n"
"\n"
"   Shortcut: Press the first letter of the option you wish to set then\n"
"             press <S> or <SPACE BAR>.\n"
"\n"
"o  To see available help for the item, use the cursor keys to highlight\n"
"   <Help> and Press <ENTER>.\n"
"\n"
"   Shortcut: Press <H> or <?>.\n"
"\n"
"   Also, the <TAB> and cursor keys will cycle between <Select> and\n"
"   <Help>\n"
"\n"
"\n"
"Data Entry\n"
"-----------\n"
"o  Enter the requested information and press <ENTER>\n"
"   If you are entering hexadecimal values, it is not necessary to\n"
"   add the '0x' prefix to the entry.\n"
"\n"
"o  For help, use the <TAB> or cursor keys to highlight the help option\n"
"   and press <ENTER>.  You can try <TAB><H> as well.\n"
"\n"
"\n"
"Text Box    (Help Window)\n"
"--------\n"
"o  Use the cursor keys to scroll up/down/left/right.  The VI editor\n"
"   keys h,j,k,l function here as do <SPACE BAR> and <B> for those\n"
"   who are familiar with less and lynx.\n"
"\n"
"o  Press <E>, <X>, <Enter> or <Esc><Esc> to exit.\n"
"\n"
"\n"
"Alternate Configuration Files\n"
"-----------------------------\n"
"Menuconfig supports the use of alternate configuration files for\n"
"those who, for various reasons, find it necessary to switch\n"
"between different configurations.\n"
"\n"
"At the end of the main menu you will find two options.  One is\n"
"for saving the current configuration to a file of your choosing.\n"
"The other option is for loading a previously saved alternate\n"
"configuration.\n"
"\n"
"Even if you don't use alternate configuration files, but you\n"
"find during a Menuconfig session that you have completely messed\n"
"up your settings, you may use the \"Load Alternate...\" option to\n"
"restore your previously saved settings from \".config\" without\n"
"restarting Menuconfig.\n"
"\n"
"Other information\n"
"-----------------\n"
"If you use Menuconfig in an XTERM window make sure you have your\n"
"$TERM variable set to point to a xterm definition which supports color.\n"
"Otherwise, Menuconfig will look rather bad.  Menuconfig will not\n"
"display correctly in a RXVT window because rxvt displays only one\n"
"intensity of color, bright.\n"
"\n"
"Menuconfig will display larger menus on screens or xterms which are\n"
"set to display more than the standard 25 row by 80 column geometry.\n"
"In order for this to work, the \"stty size\" command must be able to\n"
"display the screen's current row and column geometry.  I STRONGLY\n"
"RECOMMEND that you make sure you do NOT have the shell variables\n"
"LINES and COLUMNS exported into your environment.  Some distributions\n"
"export those variables via /etc/profile.  Some ncurses programs can\n"
"become confused when those variables (LINES & COLUMNS) don't reflect\n"
"the true screen size.\n"
"\n"
"Optional personality available\n"
"------------------------------\n"
"If you prefer to have all of the options listed in a single\n"
"menu, rather than the default multimenu hierarchy, run the menuconfig\n"
"with MENUCONFIG_MODE environment variable set to single_menu. Example:\n"
"\n"
"make MENUCONFIG_MODE=single_menu menuconfig\n"
"\n"
"<Enter> will then unroll the appropriate category, or enfold it if it\n"
"is already unrolled.\n"
"\n"
"Note that this mode can eventually be a little more CPU expensive\n"
"(especially with a larger number of unrolled categories) than the\n"
"default mode.\n",
menu_instructions[] =
	"Arrow keys navigate the menu.  "
	"<Enter> selects submenus --->.  "
	"Highlighted letters are hotkeys.  "
	"Pressing <Y> selectes a feature, while <N> will exclude a feature.  "
	"Press <Esc><Esc> to exit, <?> for Help, </> for Search.  "
	"Legend: [*] feature is selected  [ ] feature is excluded",
radiolist_instructions[] =
	"Use the arrow keys to navigate this window or "
	"press the hotkey of the item you wish to select "
	"followed by the <SPACE BAR>. "
	"Press <?> for additional information about this option.",
inputbox_instructions_int[] =
	"Please enter a decimal value. "
	"Fractions will not be accepted.  "
	"Use the <TAB> key to move from the input field to the buttons below it.",
inputbox_instructions_hex[] =
	"Please enter a hexadecimal value. "
	"Use the <TAB> key to move from the input field to the buttons below it.",
inputbox_instructions_string[] =
	"Please enter a string value. "
	"Use the <TAB> key to move from the input field to the buttons below it.",
setmod_text[] =
	"This feature depends on another which has been configured as a module.\n"
	"As a result, this feature will be built as a module.",
nohelp_text[] =
	"There is no help available for this option.\n",
load_config_text[] =
	"Enter the name of the configuration file you wish to load.  "
	"Accept the name shown to restore the configuration you "
	"last retrieved.  Leave blank to abort.",
load_config_help[] =
	"\n"
	"For various reasons, one may wish to keep several different axTLS\n"
	"configurations available on a single machine.\n"
	"\n"
	"If you have saved a previous configuration in a file other than the\n"
	"axTLS's default, entering the name of the file here will allow you\n"
	"to modify that configuration.\n"
	"\n"
	"If you are uncertain, then you have probably never used alternate\n"
	"configuration files.  You should therefor leave this blank to abort.\n",
save_config_text[] =
	"Enter a filename to which this configuration should be saved "
	"as an alternate.  Leave blank to abort.",
save_config_help[] =
	"\n"
	"For various reasons, one may wish to keep different axTLS\n"
	"configurations available on a single machine.\n"
	"\n"
	"Entering a file name here will allow you to later retrieve, modify\n"
	"and use the current configuration as an alternate to whatever\n"
	"configuration options you have selected at that time.\n"
	"\n"
	"If you are uncertain what all this means then you should probably\n"
	"leave this blank.\n",
search_help[] =
	"\n"
	"Search for CONFIG_ symbols and display their relations.\n"
	"Example: search for \"^FOO\"\n"
	"Result:\n"
	"-----------------------------------------------------------------\n"
	"Symbol: FOO [=m]\n"
	"Prompt: Foo bus is used to drive the bar HW\n"
	"Defined at drivers/pci/Kconfig:47\n"
	"Depends on: X86_LOCAL_APIC && X86_IO_APIC || IA64\n"
	"Location:\n"
	"  -> Bus options (PCI, PCMCIA, EISA, MCA, ISA)\n"
	"    -> PCI support (PCI [=y])\n"
	"      -> PCI access mode (<choice> [=y])\n"
	"Selects: LIBCRC32\n"
	"Selected by: BAR\n"
	"-----------------------------------------------------------------\n"
	"o The line 'Prompt:' shows the text used in the menu structure for\n"
	"  this CONFIG_ symbol\n"
	"o The 'Defined at' line tell at what file / line number the symbol\n"
	"  is defined\n"
	"o The 'Depends on:' line tell what symbols needs to be defined for\n"
	"  this symbol to be visible in the menu (selectable)\n"
	"o The 'Location:' lines tell where in the menu structure this symbol\n"
	"  is located\n"
	"    A location followed by a [=y] indicate that this is a selectable\n"
	"    menu item - and current value is displayed inside brackets.\n"
	"o The 'Selects:' line tell what symbol will be automatically\n"
	"  selected if this symbol is selected (y or m)\n"
	"o The 'Selected by' line tell what symbol has selected this symbol\n"
	"\n"
	"Only relevant lines are shown.\n"
	"\n\n"
	"Search examples:\n"
	"Examples: USB	=> find all CONFIG_ symbols containing USB\n"
	"          ^USB => find all CONFIG_ symbols starting with USB\n"
	"          USB$ => find all CONFIG_ symbols ending with USB\n"
	"\n";

static char filename[PATH_MAX+1] = ".config";
static int indent;
static struct termios ios_org;
static int rows = 0, cols = 0;
static struct menu *current_menu;
static int child_count;
static int single_menu_mode;

static struct dialog_list_item *items[16384]; /* FIXME: This ought to be dynamic. */
static int item_no;

static void conf(struct menu *menu);
static void conf_choice(struct menu *menu);
static void conf_string(struct menu *menu);
static void conf_load(void);
static void conf_save(void);
static void show_textbox(const char *title, const char *text, int r, int c);
static void show_helptext(const char *title, const char *text);
static void show_help(struct menu *menu);
static void show_file(const char *filename, const char *title, int r, int c);

static void init_wsize(void)
{
	struct winsize ws;
	char *env;

	if (!ioctl(STDIN_FILENO, TIOCGWINSZ, &ws)) {
		rows = ws.ws_row;
		cols = ws.ws_col;
	}

	if (!rows) {
		env = getenv("LINES");
		if (env)
			rows = atoi(env);
		if (!rows)
			rows = 24;
	}
	if (!cols) {
		env = getenv("COLUMNS");
		if (env)
			cols = atoi(env);
		if (!cols)
			cols = 80;
	}

	if (rows < 19 || cols < 80) {
		fprintf(stderr, "Your display is too small to run Menuconfig!\n");
		fprintf(stderr, "It must be at least 19 lines by 80 columns.\n");
		exit(1);
	}

	rows -= 4;
	cols -= 5;
}

static void cinit(void)
{
	item_no = 0;
}

static void cmake(void)
{
	items[item_no] = malloc(sizeof(struct dialog_list_item));
	memset(items[item_no], 0, sizeof(struct dialog_list_item));
	items[item_no]->tag = malloc(32); items[item_no]->tag[0] = 0;
	items[item_no]->name = malloc(512); items[item_no]->name[0] = 0;
	items[item_no]->namelen = 0;
	item_no++;
}

static int cprint_name(const char *fmt, ...)
{
	va_list ap;
	int res;

	if (!item_no)
		cmake();
	va_start(ap, fmt);
	res = vsnprintf(items[item_no - 1]->name + items[item_no - 1]->namelen,
			512 - items[item_no - 1]->namelen, fmt, ap);
	if (res > 0)
		items[item_no - 1]->namelen += res;
	va_end(ap);

	return res;
}

static int cprint_tag(const char *fmt, ...)
{
	va_list ap;
	int res;

	if (!item_no)
		cmake();
	va_start(ap, fmt);
	res = vsnprintf(items[item_no - 1]->tag, 32, fmt, ap);
	va_end(ap);

	return res;
}

static void cdone(void)
{
	int i;

	for (i = 0; i < item_no; i++) {
		free(items[i]->tag);
		free(items[i]->name);
		free(items[i]);
	}

	item_no = 0;
}

static void get_prompt_str(struct gstr *r, struct property *prop)
{
	int i, j;
	struct menu *submenu[8], *menu;

	str_printf(r, "Prompt: %s\n", prop->text);
	str_printf(r, "  Defined at %s:%d\n", prop->menu->file->name,
		prop->menu->lineno);
	if (!expr_is_yes(prop->visible.expr)) {
		str_append(r, "  Depends on: ");
		expr_gstr_print(prop->visible.expr, r);
		str_append(r, "\n");
	}
	menu = prop->menu->parent;
	for (i = 0; menu != &rootmenu && i < 8; menu = menu->parent)
		submenu[i++] = menu;
	if (i > 0) {
		str_printf(r, "  Location:\n");
		for (j = 4; --i >= 0; j += 2) {
			menu = submenu[i];
			str_printf(r, "%*c-> %s", j, ' ', menu_get_prompt(menu));
			if (menu->sym) {
				str_printf(r, " (%s [=%s])", menu->sym->name ?
					menu->sym->name : "<choice>",
					sym_get_string_value(menu->sym));
			}
			str_append(r, "\n");
		}
	}
}

static void get_symbol_str(struct gstr *r, struct symbol *sym)
{
	bool hit;
	struct property *prop;

	str_printf(r, "Symbol: %s [=%s]\n", sym->name,
	                               sym_get_string_value(sym));
	for_all_prompts(sym, prop)
		get_prompt_str(r, prop);
	hit = false;
	for_all_properties(sym, prop, P_SELECT) {
		if (!hit) {
			str_append(r, "  Selects: ");
			hit = true;
		} else
			str_printf(r, " && ");
		expr_gstr_print(prop->expr, r);
	}
	if (hit)
		str_append(r, "\n");
	if (sym->rev_dep.expr) {
		str_append(r, "  Selected by: ");
		expr_gstr_print(sym->rev_dep.expr, r);
		str_append(r, "\n");
	}
	str_append(r, "\n\n");
}

static struct gstr get_relations_str(struct symbol **sym_arr)
{
	struct symbol *sym;
	struct gstr res = str_new();
	int i;

	for (i = 0; sym_arr && (sym = sym_arr[i]); i++)
		get_symbol_str(&res, sym);
	if (!i)
		str_append(&res, "No matches found.\n");
	return res;
}

static void search_conf(void)
{
	struct symbol **sym_arr;
	struct gstr res;

again:
	switch (dialog_inputbox("Search Configuration Parameter",
				"Enter Keyword", 10, 75,
				NULL)) {
	case 0:
		break;
	case 1:
		show_helptext("Search Configuration", search_help);
		goto again;
	default:
		return;
	}

	sym_arr = sym_re_search(dialog_input_result);
	res = get_relations_str(sym_arr);
	free(sym_arr);
	show_textbox("Search Results", str_get(&res), 0, 0);
	str_free(&res);
}

static void build_conf(struct menu *menu)
{
	struct symbol *sym;
	struct property *prop;
	struct menu *child;
	int type, tmp, doint = 2;
	tristate val;
	char ch;

	if (!menu_is_visible(menu))
		return;

	sym = menu->sym;
	prop = menu->prompt;
	if (!sym) {
		if (prop && menu != current_menu) {
			const char *prompt = menu_get_prompt(menu);
			switch (prop->type) {
			case P_MENU:
				child_count++;
				cmake();
				cprint_tag("m%p", menu);

				if (single_menu_mode) {
					cprint_name("%s%*c%s",
						menu->data ? "-->" : "++>",
						indent + 1, ' ', prompt);
				} else {
					cprint_name("   %*c%s  --->", indent + 1, ' ', prompt);
				}

				if (single_menu_mode && menu->data)
					goto conf_childs;
				return;
			default:
				if (prompt) {
					child_count++;
					cmake();
					cprint_tag(":%p", menu);
					cprint_name("---%*c%s", indent + 1, ' ', prompt);
				}
			}
		} else
			doint = 0;
		goto conf_childs;
	}

	cmake();
	type = sym_get_type(sym);
	if (sym_is_choice(sym)) {
		struct symbol *def_sym = sym_get_choice_value(sym);
		struct menu *def_menu = NULL;

		child_count++;
		for (child = menu->list; child; child = child->next) {
			if (menu_is_visible(child) && child->sym == def_sym)
				def_menu = child;
		}

		val = sym_get_tristate_value(sym);
		if (sym_is_changable(sym)) {
			cprint_tag("t%p", menu);
			switch (type) {
			case S_BOOLEAN:
				cprint_name("[%c]", val == no ? ' ' : '*');
				break;
			case S_TRISTATE:
				switch (val) {
				case yes: ch = '*'; break;
				case mod: ch = 'M'; break;
				default:  ch = ' '; break;
				}
				cprint_name("<%c>", ch);
				break;
			}
		} else {
			cprint_tag("%c%p", def_menu ? 't' : ':', menu);
			cprint_name("   ");
		}

		cprint_name("%*c%s", indent + 1, ' ', menu_get_prompt(menu));
		if (val == yes) {
			if (def_menu) {
				cprint_name(" (%s)", menu_get_prompt(def_menu));
				cprint_name("  --->");
				if (def_menu->list) {
					indent += 2;
					build_conf(def_menu);
					indent -= 2;
				}
			}
			return;
		}
	} else {
		if (menu == current_menu) {
			cprint_tag(":%p", menu);
			cprint_name("---%*c%s", indent + 1, ' ', menu_get_prompt(menu));
			goto conf_childs;
		}
		child_count++;
		val = sym_get_tristate_value(sym);
		if (sym_is_choice_value(sym) && val == yes) {
			cprint_tag(":%p", menu);
			cprint_name("   ");
		} else {
			switch (type) {
			case S_BOOLEAN:
				cprint_tag("t%p", menu);
				if (sym_is_changable(sym))
					cprint_name("[%c]", val == no ? ' ' : '*');
				else
					cprint_name("---");
				break;
			case S_TRISTATE:
				cprint_tag("t%p", menu);
				switch (val) {
				case yes: ch = '*'; break;
				case mod: ch = 'M'; break;
				default:  ch = ' '; break;
				}
				if (sym_is_changable(sym))
					cprint_name("<%c>", ch);
				else
					cprint_name("---");
				break;
			default:
				cprint_tag("s%p", menu);
				tmp = cprint_name("(%s)", sym_get_string_value(sym));
				tmp = indent - tmp + 4;
				if (tmp < 0)
					tmp = 0;
				cprint_name("%*c%s%s", tmp, ' ', menu_get_prompt(menu),
					(sym_has_value(sym) || !sym_is_changable(sym)) ?
					"" : " (NEW)");
				goto conf_childs;
			}
		}
		cprint_name("%*c%s%s", indent + 1, ' ', menu_get_prompt(menu),
			(sym_has_value(sym) || !sym_is_changable(sym)) ?
			"" : " (NEW)");
		if (menu->prompt->type == P_MENU) {
			cprint_name("  --->");
			return;
		}
	}

conf_childs:
	indent += doint;
	for (child = menu->list; child; child = child->next)
		build_conf(child);
	indent -= doint;
}

static void conf(struct menu *menu)
{
	struct dialog_list_item *active_item = NULL;
	struct menu *submenu;
	const char *prompt = menu_get_prompt(menu);
	struct symbol *sym;
	char active_entry[40];
	int stat, type;

	unlink("lxdialog.scrltmp");
	active_entry[0] = 0;
	while (1) {
		indent = 0;
		child_count = 0;
		current_menu = menu;
		cdone(); cinit();
		build_conf(menu);
		if (!child_count)
			break;
		if (menu == &rootmenu) {
			cmake(); cprint_tag(":"); cprint_name("--- ");
			cmake(); cprint_tag("L"); cprint_name("Load an Alternate Configuration File");
			cmake(); cprint_tag("S"); cprint_name("Save Configuration to an Alternate File");
		}
		dialog_clear();
		stat = dialog_menu(prompt ? prompt : "Main Menu",
				menu_instructions, rows, cols, rows - 10,
				active_entry, item_no, items);
		if (stat < 0)
			return;

		if (stat == 1 || stat == 255)
			break;

		active_item = first_sel_item(item_no, items);
		if (!active_item)
			continue;
		active_item->selected = 0;
		strncpy(active_entry, active_item->tag, sizeof(active_entry));
		active_entry[sizeof(active_entry)-1] = 0;
		type = active_entry[0];
		if (!type)
			continue;

		sym = NULL;
		submenu = NULL;
		if (sscanf(active_entry + 1, "%p", &submenu) == 1)
			sym = submenu->sym;

		switch (stat) {
		case 0:
			switch (type) {
			case 'm':
				if (single_menu_mode)
					submenu->data = (void *) (long) !submenu->data;
				else
					conf(submenu);
				break;
			case 't':
				if (sym_is_choice(sym) && sym_get_tristate_value(sym) == yes)
					conf_choice(submenu);
				else if (submenu->prompt->type == P_MENU)
					conf(submenu);
				break;
			case 's':
				conf_string(submenu);
				break;
			case 'L':
				conf_load();
				break;
			case 'S':
				conf_save();
				break;
			}
			break;
		case 2:
			if (sym)
				show_help(submenu);
			else
				show_helptext("README", mconf_readme);
			break;
		case 3:
			if (type == 't') {
				if (sym_set_tristate_value(sym, yes))
					break;
				if (sym_set_tristate_value(sym, mod))
					show_textbox(NULL, setmod_text, 6, 74);
			}
			break;
		case 4:
			if (type == 't')
				sym_set_tristate_value(sym, no);
			break;
		case 5:
			if (type == 't')
				sym_set_tristate_value(sym, mod);
			break;
		case 6:
			if (type == 't')
				sym_toggle_tristate_value(sym);
			else if (type == 'm')
				conf(submenu);
			break;
		case 7:
			search_conf();
			break;
		}
	}
}

static void show_textbox(const char *title, const char *text, int r, int c)
{
	int fd;

	fd = creat(".help.tmp", 0777);
	write(fd, text, strlen(text));
	close(fd);
	show_file(".help.tmp", title, r, c);
	unlink(".help.tmp");
}

static void show_helptext(const char *title, const char *text)
{
	show_textbox(title, text, 0, 0);
}

static void show_help(struct menu *menu)
{
	struct gstr help = str_new();
	struct symbol *sym = menu->sym;

	if (sym->help)
	{
		if (sym->name) {
			str_printf(&help, "%s:\n\n", sym->name);
			str_append(&help, sym->help);
			str_append(&help, "\n");
		}
	} else {
		str_append(&help, nohelp_text);
	}
	get_symbol_str(&help, sym);
	show_helptext(menu_get_prompt(menu), str_get(&help));
	str_free(&help);
}

static void show_file(const char *filename, const char *title, int r, int c)
{
	while (dialog_textbox(title, filename, r ? r : rows, c ? c : cols) < 0)
		;
}

static void conf_choice(struct menu *menu)
{
	const char *prompt = menu_get_prompt(menu);
	struct menu *child;
	struct symbol *active;

	active = sym_get_choice_value(menu->sym);
	while (1) {
		current_menu = menu;
		cdone(); cinit();
		for (child = menu->list; child; child = child->next) {
			if (!menu_is_visible(child))
				continue;
			cmake();
			cprint_tag("%p", child);
			cprint_name("%s", menu_get_prompt(child));
			if (child->sym == sym_get_choice_value(menu->sym))
				items[item_no - 1]->selected = 1; /* ON */
			else if (child->sym == active)
				items[item_no - 1]->selected = 2; /* SELECTED */
			else
				items[item_no - 1]->selected = 0; /* OFF */
		}

		switch (dialog_checklist(prompt ? prompt : "Main Menu",
					radiolist_instructions, 15, 70, 6,
					item_no, items, FLAG_RADIO)) {
		case 0:
			if (sscanf(first_sel_item(item_no, items)->tag, "%p", &child) != 1)
				break;
			sym_set_tristate_value(child->sym, yes);
			return;
		case 1:
			if (sscanf(first_sel_item(item_no, items)->tag, "%p", &child) == 1) {
				show_help(child);
				active = child->sym;
			} else
				show_help(menu);
			break;
		case 255:
			return;
		}
	}
}

static void conf_string(struct menu *menu)
{
	const char *prompt = menu_get_prompt(menu);

	while (1) {
		char *heading;

		switch (sym_get_type(menu->sym)) {
		case S_INT:
			heading = (char *) inputbox_instructions_int;
			break;
		case S_HEX:
			heading = (char *) inputbox_instructions_hex;
			break;
		case S_STRING:
			heading = (char *) inputbox_instructions_string;
			break;
		default:
			heading = "Internal mconf error!";
			/* panic? */;
		}

		switch (dialog_inputbox(prompt ? prompt : "Main Menu",
					heading, 10, 75,
					sym_get_string_value(menu->sym))) {
		case 0:
			if (sym_set_string_value(menu->sym, dialog_input_result))
				return;
			show_textbox(NULL, "You have made an invalid entry.", 5, 43);
			break;
		case 1:
			show_help(menu);
			break;
		case 255:
			return;
		}
	}
}

static void conf_load(void)
{
	while (1) {
		switch (dialog_inputbox(NULL, load_config_text, 11, 55,
					filename)) {
		case 0:
			if (!dialog_input_result[0])
				return;
			if (!conf_read(dialog_input_result))
				return;
			show_textbox(NULL, "File does not exist!", 5, 38);
			break;
		case 1:
			show_helptext("Load Alternate Configuration", load_config_help);
			break;
		case 255:
			return;
		}
	}
}

static void conf_save(void)
{
	while (1) {
		switch (dialog_inputbox(NULL, save_config_text, 11, 55,
					filename)) {
		case 0:
			if (!dialog_input_result[0])
				return;
			if (!conf_write(dialog_input_result))
				return;
			show_textbox(NULL, "Can't create file!  Probably a nonexistent directory.", 5, 60);
			break;
		case 1:
			show_helptext("Save Alternate Configuration", save_config_help);
			break;
		case 255:
			return;
		}
	}
}

static void conf_cleanup(void)
{
	tcsetattr(1, TCSAFLUSH, &ios_org);
	unlink(".help.tmp");
}

static void winch_handler(int sig)
{
	struct winsize ws;

	if (ioctl(1, TIOCGWINSZ, &ws) == -1) {
		rows = 24;
		cols = 80;
	} else {
		rows = ws.ws_row;
		cols = ws.ws_col;
	}

	if (rows < 19 || cols < 80) {
		end_dialog();
		fprintf(stderr, "Your display is too small to run Menuconfig!\n");
		fprintf(stderr, "It must be at least 19 lines by 80 columns.\n");
		exit(1);
	}

	rows -= 4;
	cols -= 5;

}

int main(int ac, char **av)
{
	struct symbol *sym;
	char *mode;
	int stat;

	conf_parse(av[1]);
	conf_read(NULL);

	sym = sym_lookup("VERSION", 0);
	sym_calc_value(sym);
	snprintf(menu_backtitle, 128, "axTLS v%s Configuration",
		sym_get_string_value(sym));

	mode = getenv("MENUCONFIG_MODE");
	if (mode) {
		if (!strcasecmp(mode, "single_menu"))
			single_menu_mode = 1;
	}

	tcgetattr(1, &ios_org);
	atexit(conf_cleanup);
	init_wsize();
	init_dialog();
	signal(SIGWINCH, winch_handler);
	conf(&rootmenu);
	end_dialog();

	/* Restart dialog to act more like when lxdialog was still separate */
	init_dialog();
	do {
		stat = dialog_yesno(NULL,
				    "Do you wish to save your new axTLS configuration?", 5, 60);
	} while (stat < 0);
	end_dialog();

	if (stat == 0) {
		conf_write(NULL);
		printf("\n\n"
			"*** End of axTLS configuration.\n"
			"*** Check the top-level Makefile for additional configuration options.\n\n");
	} else
		printf("\n\nYour axTLS configuration changes were NOT saved.\n\n");

	return 0;
}
