"""Splunk REST endpoint for listing, creating, and deleting albums."""

import json
import logging
import sys
from pathlib import Path

from splunk.persistconn.application import PersistentServerConnectionApplication

sys.path.insert(0, str(Path(__file__).resolve().parent))
from albums_db import create_album, delete_album, list_albums


logger = logging.getLogger(__name__)


def _reply(payload, status):
    return {
        "payload": payload,
        "status": status,
        "headers": {"Content-Type": "application/json"},
    }


class AlbumsApi(PersistentServerConnectionApplication):
    def __init__(self, command_line, command_arg):
        super().__init__()

    def handle(self, in_string):
        try:
            request = json.loads(in_string)
            method = request.get("method")

            if method == "GET":
                return _reply({"albums": list_albums()}, 200)

            if method == "POST":
                fields = dict(request.get("form", []))
                if fields.get("action") == "delete":
                    if delete_album(fields.get("id", "")):
                        return _reply({"deleted": True}, 200)
                    return _reply({"error": "Album not found"}, 404)
                if fields.get("action") not in (None, "create"):
                    return _reply({"error": "Unknown action"}, 400)
                album_id = create_album(
                    fields.get("album_name", ""),
                    fields.get("artist_name", ""),
                )
                return _reply({"id": album_id}, 201)

            return _reply({"error": "Method not allowed"}, 405)
        except (ValueError, TypeError) as exc:
            return _reply({"error": str(exc)}, 400)
        except Exception:
            logger.exception("Album API failed")
            return _reply({"error": "Could not access albums"}, 500)
