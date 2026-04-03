function sun_vec = sun_position_eci(jd)
    d = jd - 2451545.0;
    g = deg2rad(mod(357.528 + 0.9856003 * d, 360));
    lambda = deg2rad(mod(280.460 + 0.9856474 * d + 1.915 * sin(g) + 0.020 * sin(2*g), 360));
    epsilon = deg2rad(23.439 - 0.0000004 * d);
    r = 1.00014 - 0.01671 * cos(g) - 0.00014 * cos(2 * g);

    x = r * cos(lambda);
    y = r * cos(epsilon) * sin(lambda);
    z = r * sin(epsilon) * sin(lambda);
    AU = 149597870.7;
    sun_vec = [x, y, z] * AU;
end
