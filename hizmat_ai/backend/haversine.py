"""
Haversine distance calculation — used by RankAgent to compute
km distance between user location and each provider.
No Maps API required.
"""
import math


def haversine(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    """
    Returns distance in kilometres between two (lat, lng) coordinates.
    Uses the Haversine formula which accounts for Earth's curvature.
    Accurate to ~0.5% for distances up to ~200km (sufficient for Karachi metro).
    """
    R = 6371.0  # Earth radius in km

    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlambda = math.radians(lng2 - lng1)

    a = math.sin(dphi / 2) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlambda / 2) ** 2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))

    return R * c
