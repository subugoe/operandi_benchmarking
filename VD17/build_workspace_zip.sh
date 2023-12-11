#!/bin/bash

export OCRD_DOWNLOAD_TIMEOUT=15
export OCRD_DOWNLOAD_RETRIES=3

WORKSPACE_DIR="urn_nbn_de_bsz_14-db-id3272770845"
OCRD_IDENTIFIER="urn nbn de bsz 14-db-id3272770845"
ORIRIGNAL_METS="$OCRD_IDENTIFIER.xml"

cp "$WORKSPACE_DIR/$ORIRIGNAL_METS" "$WORKSPACE_DIR/mets.xml"
ocrd workspace -d "$WORKSPACE_DIR" -m mets.xml find -q MAX --download
ocrd zip bag -d "$WORKSPACE_DIR" -m mets.xml -i "$OCRD_IDENTIFIER" -q MAX --processes 4
rm "$WORKSPACE_DIR/mets.xml"
rm -rf "$WORKSPACE_DIR/MAX"
