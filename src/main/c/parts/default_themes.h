/* libxmq - Copyright (C) 2024-2026 Fredrik Öhrström (spdx: MIT)

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#ifndef DEFAULT_THEMES_H
#define DEFAULT_THEMES_H

#ifndef BUILDING_DIST_XMQ
#include "xmq.h"
#endif

struct XMQTheme;
typedef struct XMQTheme XMQTheme;

/**
   A theme_spec looks like this:

   export XMQ_COLORS=C=#ffffff:Q=#ff0000:E=#ff0000
   This will override the colors for the comments, quotes and entities, for both dark and light modes.

   You can also specify --colors=C=#ffffff:Q=#ff0000:E=#ff0000

   export XMQ_COLORS=dark+C=#ff0000_U:AKV=#00ff00_B,light+E=#000000
   This will make different overrides for dark and light modes.

   export XMQ_COLORS_moo=dark+C=ffff00:AKV=001122_B,light+E=112233
   You can now specify --theme=moo and depending on the background moo-dark or moo-light will be used.

   Normally xmq detects wether the background is dark or light.
   But you can force this with --bg=light or --bg=dark or XMQ_BG=light or XMG_BG=dark

   There are the available colors:
   C comment
   Q quote
   E entity
   NS name space
   EN element name with children
   EK element name as key
   EKV element key value
   AK attribute key
   AKV attribute key value
   CP composiste parentheses
   NSD name space declaration
   UW unicode whitespace
   XLS the xls namespace

*/

bool installTheme(XMQTheme *theme, const char *theme_spec);
const char *ansiWin(int i);

#define DEFAULT_THEMES_MODULE

#endif // DEFAULT_THEMES_H
