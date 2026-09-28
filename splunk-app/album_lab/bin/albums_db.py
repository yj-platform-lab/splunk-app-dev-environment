"""Read and write albums in the local MySQL database."""

from __future__ import annotations

import os
import sys
from pathlib import Path

# Splunk uses the app-local packages; OS Python uses its own installation.
if Path(sys.executable).is_relative_to("/opt/splunk"):
    sys.path.insert(0, str(Path(__file__).resolve().parent / "lib"))

import pymysql


def _connect():
    return pymysql.connect(
        unix_socket="/var/lib/mysql/mysql.sock",
        user=os.environ["MYSQL_APP_USER"],
        password=os.environ["MYSQL_APP_PASSWORD"],
        database=os.environ["MYSQL_DATABASE"],
        charset="utf8mb4",
        cursorclass=pymysql.cursors.DictCursor,
    )


def create_album(album_name: str, artist_name: str) -> int:
    """Insert an album and return its new ID."""
    album_name = album_name.strip()
    artist_name = artist_name.strip()
    if not album_name or not artist_name:
        raise ValueError("Album name and artist name are required")
    if len(album_name) > 255 or len(artist_name) > 255:
        raise ValueError("Album name and artist name must be at most 255 characters")

    connection = _connect()
    try:
        with connection.cursor() as cursor:
            cursor.execute(
                "INSERT INTO albums (album_name, artist_name) VALUES (%s, %s)",
                (album_name, artist_name),
            )
            album_id = cursor.lastrowid
        connection.commit()
        return album_id
    finally:
        connection.close()


def list_albums() -> list[dict[str, object]]:
    """Return albums from newest to oldest, ready for a JSON response."""
    connection = _connect()
    try:
        with connection.cursor() as cursor:
            cursor.execute(
                "SELECT id, album_name, artist_name, created_at "
                "FROM albums ORDER BY id DESC"
            )
            albums = cursor.fetchall()
        for album in albums:
            album["created_at"] = album["created_at"].isoformat(sep=" ")
        return albums
    finally:
        connection.close()


def delete_album(album_id: str) -> bool:
    """Delete one album by ID; return False when it does not exist."""
    if (not isinstance(album_id, str) or not album_id.isascii()
            or not album_id.isdecimal()):
        raise ValueError("A valid album ID is required")
    numeric_id = int(album_id)
    if not 1 <= numeric_id <= 2**64 - 1:
        raise ValueError("A valid album ID is required")

    connection = _connect()
    try:
        with connection.cursor() as cursor:
            cursor.execute("DELETE FROM albums WHERE id = %s", (numeric_id,))
            deleted = cursor.rowcount > 0
        connection.commit()
        return deleted
    finally:
        connection.close()
