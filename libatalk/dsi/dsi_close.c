/*
 * $Id: dsi_close.c,v 1.4 2003-03-12 15:07:06 didg Exp $
 *
 * Copyright (c) 1997 Adrian Sun (asun@zoology.washington.edu)
 * All rights reserved. See COPYRIGHT.
 */

#include "config.h"

#include <stdio.h>
#include <stdlib.h>
#include <atalk/dsi.h>
#include <netatalk/endian.h>

void dsi_close(DSI * dsi)
{
	/* server generated. need to set all the fields. */
	if (!(dsi->flags & DSI_SLEEPING)
	    && !(dsi->flags & DSI_DISCONNECTED)) {
		dsi->header.dsi_flags = DSIFL_REQUEST;
		dsi->header.dsi_command = DSIFUNC_CLOSE;
		dsi->header.dsi_requestID = htons(dsi_serverID(dsi));
		dsi->header.dsi_code = dsi->header.dsi_reserved = htonl(0);
		dsi->cmdlen = 0;
		dsi_send(dsi);
		dsi->proto_close(dsi);
	}
	free(dsi);
}
