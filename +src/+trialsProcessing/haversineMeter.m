function [dist,a,c,dlat,dlon]=haversineMeter(lat1,lon1,lat2,lon2)
% [dist,a,c,dlat,dlon] = haversineMeter(minLat,minLon,maxLat,maxLon)
%
% User Kaimbridge clarified on the Talk page:
% 
%  -- 6371.0 km is the authalic radius based on/extracted from surface area;
%  -- 6372.8 km is an approximation of the radius of the average circumference
%     (i.e., the average great-elliptic or great-circle radius), where the
%      boundaries are the meridian (6367.45 km) and the equator (6378.14 km).
% 
% Using either of these values results, of course, in differing distances:
% 
%  6371.0 km -> 2886.44444283798329974715782394574671655 km;
%  6372.8 km -> 2887.25995060711033944886005029688505340 km;
%  (results extended for accuracy check:  Given that the radii are only
%   approximations anyways, .01' ≈ 1.0621333 km and .001" ≈ .00177 km,
%   practical precision required is certainly no greater than about
%   .0000001——i.e., .1 mm!)
% 
% As distances are segments of great circles/circumferences, it is
% recommended that the latter value (r = 6372.8 km) be used (which
% most of the given solutions have already adopted, anyways).
%
% This function, given the geocordinates of two nodes, it can calculate
% the Euclidean distance between them 

    dlat = deg2rad(lat2-lat1);
    dlon = deg2rad(lon2-lon1);
    lat1 = deg2rad(lat1);
    lat2 = deg2rad(lat2);
    a = (sin(dlat./2)).^2 + cos(lat1) .* cos(lat2) .* (sin(dlon./2)).^2;
    c = 2 .* asin(sqrt(a));
    dist = 6372.8*c*1000;
end
