function animation(times, satrec)

figure;
worldmap world
load coastlines
plotm(coastlat, coastlon)

title('Satellite Ground Track Animation');
xlabel('Longitude');
ylabel('Latitude');

for i = 1:length(times)
    t = times(i);
    [jd, fr] = jday(t.Year, t.Month, t.Day, t.Hour, t.Minute, t.Second);
    tsince = (jd + fr - satrec.jdsatepoch) * 1440;

    [e, r_eci, ~] = sgp4(satrec, tsince);
    if e ~= 0, continue; end

    % ECI → ECEF
    jd_full = jd + fr;
    theta_g = 280.46061837 + 360.98564736629 * (jd_full - 2451545.0);
    theta_g = mod(theta_g, 360);
    theta_rad = deg2rad(theta_g);

    R = [cos(theta_rad), sin(theta_rad), 0;
        -sin(theta_rad), cos(theta_rad), 0;
         0,              0,              1];
    r_ecef = R * r_eci(:);

    % ECEF
    [lat, lon, alt] = ecef_to_geodetic(r_ecef(1), r_ecef(2), r_ecef(3));

    % 위성 위치
    plotm(lat, lon, 'ro', 'MarkerSize', 5, 'MarkerFaceColor', 'r');
    pause(0.01);
end

end
