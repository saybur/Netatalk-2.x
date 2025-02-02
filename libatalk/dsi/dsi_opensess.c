/*
 * Copyright (c) 1997 Adrian Sun (asun@zoology.washington.edu)
 * All rights reserved. See COPYRIGHT.
 */

#include "config.h"

#include <stdio.h>
#include <string.h>
#include <sys/types.h>
#include <stdlib.h>
#include <inttypes.h>

#include <atalk/dsi.h>
#include <atalk/util.h>
#include <atalk/logger.h>

static void dsi_init_buffer(DSI * dsi)
{
	size_t quantum =
	    dsi->server_quantum ? dsi->server_quantum : DSI_SERVQUANT_DEF;

	/* default is 12 * 300k = 3,6 MB (Apr 2011) */
	if ((dsi->buffer = malloc(dsi->dsireadbuf * quantum)) == NULL) {
		LOG(log_error, logtype_dsi, "dsi_init_buffer: OOM");
		AFP_PANIC("OOM in dsi_init_buffer");
	}
	dsi->start = dsi->buffer;
	dsi->eof = dsi->buffer;
	dsi->end = dsi->buffer + (dsi->dsireadbuf * quantum);
}

/* OpenSession. set up the connection */
void dsi_opensession(DSI * dsi)
{
  size_t i = 0;
  uint32_t servquant;
  uint32_t replcsize;
  int offs;
  uint8_t cmd;
  size_t option_len;

  dsi_init_buffer(dsi);
  if (setnonblock(dsi->socket, 1) < 0) {
      LOG(log_error, logtype_dsi, "dsi_opensession: setnonblock: %s", strerror(errno));
      AFP_PANIC("setnonblock error");
  }

  /* parse options */
  while (i + 1 < dsi->cmdlen) {
    cmd = dsi->commands[i++];
    option_len = dsi->commands[i++];

    if (i + option_len > dsi->cmdlen) {
      LOG(log_error, logtype_dsi, "option %ux too large: %zu",
          cmd, option_len);
      exit(EXITERR_CLNT);
    }

    switch (cmd) {
    case DSIOPT_ATTNQUANT:
      if (option_len != sizeof(dsi->attn_quantum)) {
        LOG(log_error, logtype_dsi, "option %ux bad length: %zu",
            cmd, option_len);
        exit(EXITERR_CLNT);
      }
      memcpy(&dsi->attn_quantum, &dsi->commands[i], option_len);
      dsi->attn_quantum = ntohl(dsi->attn_quantum);

    case DSIOPT_SERVQUANT: /* just ignore these */
    default:
      break;
    }

    i += option_len;
  }

  /* let the client know the server quantum. we don't use the
   * max server quantum due to a bug in appleshare client 3.8.6. */
  dsi->header.dsi_flags = DSIFL_REPLY;
  dsi->header.dsi_code = 0;
  /* dsi->header.dsi_command = DSIFUNC_OPEN;*/

  dsi->cmdlen = 2 * (2 + sizeof(uint32_t)); /* length of data. dsi_send uses it. */

  /* DSI Option Server Request Quantum */
  dsi->commands[0] = DSIOPT_SERVQUANT;
  dsi->commands[1] = sizeof(servquant);
  servquant = htonl(( dsi->server_quantum < DSI_SERVQUANT_MIN ||
	      dsi->server_quantum > DSI_SERVQUANT_MAX ) ? 
	    DSI_SERVQUANT_DEF : dsi->server_quantum);
  memcpy(dsi->commands + 2, &servquant, sizeof(servquant));

  /* AFP replaycache size option */
  offs = 2 + sizeof(replcsize);
  dsi->commands[offs] = DSIOPT_REPLCSIZE;
  dsi->commands[offs+1] = sizeof(replcsize);
  replcsize = htonl(REPLAYCACHE_SIZE);
  memcpy(dsi->commands + offs + 2, &replcsize, sizeof(replcsize));
  dsi_send(dsi);
}
