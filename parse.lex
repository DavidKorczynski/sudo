%{
/*
 * CU sudo version 1.3.1 (based on Root Group sudo version 1.1)
 *
 * This software comes with no waranty whatsoever, use at your own risk.
 *
 * Please send bugs, changes, problems to sudo-bugs.cs.colorado.edu
 *
 */

/*
 *  sudo version 1.1 allows users to execute commands as root
 *  Copyright (C) 1991  The Root Group, Inc.
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 1, or (at your option)
 *  any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 *
 */
/*******************************************************************************
* parse.lex, sudo project
* David R. Hieb
* March 18, 1991
*
* Lex Specification file for the sudo project.
*******************************************************************************/

#ifndef lint
static char rcsid[] = "$Id$";
#endif /* lint */

#include "config.h"
#ifdef HAVE_UNISTD_H
#include <unistd.h>
#endif /* HAVE_UNISTD_H */
#include <ctype.h>
#include <sys/types.h>
#include <sys/param.h>
#include <netinet/in.h>
#include "sudo.h"
#include "options.h"
#include "y.tab.h"

extern YYSTYPE yylval;
int sudolineno = 1;

static int fill(void);

#ifdef TRACELEXER
#define LEXTRACE(msg)	fputs(msg, stderr)
#else
#define LEXTRACE(msg)
#endif
%}

D			[0-9]
N			{D}{1,3}

%e	4000
%p	6000
%k	3500

%%
[ \t]+			{ ; }			/* throw away space/tabs */
\\\n			{ 
			  ++sudolineno;
			  LEXTRACE("\n\t");
			}			/* throw away EOL after \ */
\,			{ return ','; }		/* return ',' */
\!			{ return '!'; }		/* return '!' */
=			{
			  LEXTRACE("= ");
			  return '=';
			}			/* return '=' */
:			{
			  LEXTRACE(": ");
			  return ':';
			}			/* return ':' */
\.			{ return '.'; }
\n			{ 
			  ++sudolineno; 
			  LEXTRACE("\n");
			  return COMMENT;
			}			/* return newline */
#.*\n			{
			  ++sudolineno;
			  LEXTRACE("\n");
			  return COMMENT;
			}			/* return comments */
[@$%^&*()"'`/_+.]*	{ return ERROR; }	/* return error */
[?;<>\[\]{}|~-]*	{ return ERROR; }	/* return error */

{N}\.{N}\.{N}\.{N}	{ fill(); return NTWKADDR; }

\/([a-zA-Z0-9_.+-]+\/?)+ {
			  LEXTRACE("PATH ");
			  fill();
			  return PATH;
			}			/* a pathname */

[A-Z][A-Z0-9_]*		{
			  fill();
			  if (strcmp(yytext, "ALL") == 0) {
			      LEXTRACE("ALL ");
			      return ALL;
			  }
			  LEXTRACE("ALIAS ");
			  return ALIAS;
			}

[a-zA-Z][a-zA-Z0-9_-]*	{
			  int l;

			  fill();
			  if (strcmp(yytext, "Host_Alias") == 0) {
			      LEXTRACE("HOSTALIAS ");
			      return HOSTALIAS;
			  }
			  if (strcmp(yytext, "Cmnd_Alias") == 0) {
			      LEXTRACE("CMNDALIAS ");
			      return CMNDALIAS;
			  }

			  l = strlen(yytext) - 1;
			  if (isalpha(yytext[l]) || isdigit(yytext[l])) {
			      /* NAME is what RFC1034 calls a label */
			      LEXTRACE("NAME ");
			      return NAME;
			  }

			  return ERROR;
			}

%%
static int fill(void) {
    (void) strcpy(yylval.string, yytext);
}
