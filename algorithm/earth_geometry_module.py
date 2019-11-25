import numpy as np
#Great circle distance calculation between to lat/lon coordinates
#output is in km
def gc_distance(lat1, lng1, lat2, lng2):
    radius = 6371 

    dLat = (lat2-lat1) * np.pi / 180
    dLng = (lng2-lng1) * np.pi / 180

    lat1 = lat1 * np.pi / 180
    lat2 = lat2 * np.pi / 180

    val = np.sin(dLat/2) * np.sin(dLat/2) + np.sin(dLng/2) * np.sin(dLng/2) * np.cos(lat1) * np.cos(lat2) 
   
    ang = 2 * np.arctan2(np.sqrt(val), np.sqrt(1-val))
    return radius * ang
