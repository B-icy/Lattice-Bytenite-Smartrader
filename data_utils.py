"""Utility helpers for validating and formatting model outputs.

These functions provide defensive guards against hallucinated agent data and
standardised formatting for the markdown reports.
"""

import datetime
from typing import Optional, Sequence


def is_price_analysis_reliable(pa) -> bool:
    """Return True when the price-analysis block looks numerically plausible."""

    try:
        if pa is None:
            return False
        if pa.total_return_percent is None or abs(pa.total_return_percent) > 400:
            return False
        if pa.volatility is None or pa.volatility < 0 or pa.volatility > 200:
            return False
        if pa.min_price is None or pa.max_price is None or pa.min_price <= 0 or pa.max_price <= 0:
            return False
        if pa.min_price >= pa.max_price:
            return False
        if pa.average_volume is None or pa.average_volume <= 0:
            return False
    except AttributeError:
        return False
    return True


def sanitize_dividend_yield(raw: Optional[float]) -> Optional[float]:
    """Clamp extreme dividend yields and convert percents to fractions."""

    if raw is None or raw < 0:
        return None
    if raw > 1000:
        return None
    if raw > 50:
        return None
    if raw > 1:
        normalized = raw / 100
        return normalized if normalized <= 0.25 else None
    return raw


def format_percent(raw: Optional[float], decimals: int = 2, *, assume_fractional: bool = False) -> str:
    """Format numbers as percentages while tolerating fractional inputs."""

    if raw is None:
        return "N/A"
    try:
        value = float(raw)
    except (TypeError, ValueError):
        return "N/A"
    if assume_fractional or abs(value) <= 1:
        value *= 100
    return f"{value:.{decimals}f}%"


def format_ratio(raw: Optional[float], decimals: int = 2) -> str:
    """Render floats with a fixed precision, falling back to 'N/A'."""

    if raw is None:
        return "N/A"
    return f"{raw:.{decimals}f}"


def format_currency(raw: Optional[float]) -> str:
    """Format numbers as currency strings or return 'N/A'."""

    if raw is None:
        return "N/A"
    try:
        value = float(raw)
    except (TypeError, ValueError):
        return "N/A"
    return f"${value:,.2f}"


def format_integer(raw: Optional[float]) -> str:
    """Format values as thousands-separated integers with graceful fallback."""

    if raw is None:
        return "N/A"
    try:
        return f"{int(round(float(raw))):,}"
    except (TypeError, ValueError):
        return "N/A"


PLACEHOLDER_NAMES = {"john doe", "jane smith", "alice johnson"}


def filter_recent_articles(articles: Sequence, as_of: datetime.date, max_age_days: int = 120):
    """Return only articles published within ``max_age_days`` of ``as_of``."""

    def _parse_date(value: str):
        if not value:
            return None
        value = value.strip()
        for fmt in ("%Y-%m-%d", "%Y-%m-%dT%H:%M:%SZ", "%Y-%m-%dT%H:%M:%S", "%Y-%m-%d %H:%M:%S"):
            try:
                return datetime.datetime.strptime(value, fmt).date()
            except ValueError:
                continue
        try:
            return datetime.datetime.fromisoformat(value.replace("Z", "+00:00")).date()
        except ValueError:
            return None

    recent = []
    for article in articles or []:
        published_on = _parse_date(getattr(article, "published_date", ""))
        if not published_on:
            continue
        if as_of - published_on > datetime.timedelta(days=max_age_days):
            continue
        recent.append(article)
    return recent


def filter_valid_transactions(transactions: Sequence) -> list:
    """Drop placeholder insider names from transaction lists."""

    valid = []
    for txn in transactions or []:
        name = getattr(txn, "name", "").strip().lower()
        if not name or name in PLACEHOLDER_NAMES:
            continue
        valid.append(txn)
    return valid


def is_valid_volatility_metrics(metrics) -> bool:
    """Validate volatility metrics, filtering out impossible values."""

    try:
        if metrics is None:
            return False
        hv = getattr(metrics, "historical_volatility", None)
        if hv is None or hv < 0 or hv > 250:
            return False
        md = getattr(metrics, "max_drawdown", None)
        if md is None or md > 0 or md < -100:
            return False
    except AttributeError:
        return False
    return True


def filter_recent_transactions(transactions: Sequence, as_of: datetime.date, max_age_days: int = 365) -> list:
    """Return insider trades within ``max_age_days`` of the report date."""

    def _parse(value: str):
        if not value:
            return None
        value = value.strip()
        for fmt in ("%Y-%m-%d", "%Y-%m-%dT%H:%M:%SZ", "%Y-%m-%d %H:%M:%S"):
            try:
                return datetime.datetime.strptime(value, fmt).date()
            except ValueError:
                continue
        try:
            return datetime.datetime.fromisoformat(value.replace("Z", "+00:00")).date()
        except ValueError:
            return None

    recent = []
    for txn in filter_valid_transactions(transactions):
        txn_date = _parse(getattr(txn, "transaction_date", ""))
        if not txn_date:
            continue
        if as_of - txn_date > datetime.timedelta(days=max_age_days):
            continue
        recent.append(txn)
    return recent
