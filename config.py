"""Helpers for loading configuration and runtime metadata.

This module centralises environment-variable validation and light-weight
configuration used by both the CLI entrypoint and the report generator.
"""

import datetime
import os


def ensure_env_var(name: str) -> str:
    """Return the value of a required environment variable or raise."""

    value = os.getenv(name)
    if not value:
        raise RuntimeError(f"{name} is not set. Update your .env or environment variables.")
    return value


def warn_if_missing(name: str) -> None:
    """Emit a non-fatal warning when optional credentials are absent."""

    if not os.getenv(name):
        print(f"[warning] {name} is not configured; related data sources may be limited.")


def get_report_date() -> datetime.date:
    """Resolve the reporting 'as-of' date, honouring an optional override."""

    override = os.getenv("REPORT_AS_OF_DATE")
    if override:
        try:
            return datetime.date.fromisoformat(override)
        except ValueError:
            print(f"[warning] REPORT_AS_OF_DATE '{override}' is invalid; using today's date instead.")
    return datetime.date.today()
