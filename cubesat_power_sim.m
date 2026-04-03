function cubesat_power_sim(tle, start_time, duration_days)

% 시뮬레이션 설정
sim_start = start_time;
sim_end = sim_start + days(duration_days);
step = minutes(1);

% 시나리오 객체
sc = satelliteScenario(sim_start, sim_end, 60);

% TLE 준비 (char 형식)
sat = satellite(sc, tle);

% 연세대 지상국
lat = 37.5; lon = 126.9; alt = 0.1;
gs = groundStation(sc, lat, lon, alt);

% 시간 벡터
times = sim_start:step:sim_end;
n = length(times);

% 위성 및 태양 관련 설정
panel_area = 0.01;
solar_constant = 1361;
efficiency = 0.25;
Re = 6378.137;

powers = zeros(1, n);

for i = 1:n
    t = times(i);
    r = states(sat, t, 'CoordinateFrame', 'inertial');
    r = r(1:3);

    jd = juliandate(t);
    sun_vec = sun_position_eci(jd);

    % Eclipse 판단
    sat_to_sun = sun_vec - r;
    sat_to_sun_unit = sat_to_sun / norm(sat_to_sun);
    dot_prod = dot(r, sat_to_sun_unit);
    closest = r - dot_prod * sat_to_sun_unit;
    dist = norm(closest);
    in_eclipse = (dot_prod > 0) && (dist < Re);
    if in_eclipse
        powers(i) = 0;
        continue;
    end

    % 자세 가정
    z_body = -r / norm(r);
    x_cand = cross([0 0 1], z_body);
    if norm(x_cand) < 1e-6
        x_cand = cross([1 0 0], z_body);
    end
    x_body = x_cand / norm(x_cand);
    y_body = cross(z_body, x_body);

    sun_unit = sun_vec / norm(sun_vec);
    candidates = [x_body; -x_body; y_body; -y_body];
    best_dot = max(candidates * sun_unit');
    theta = acos(best_dot);
    power = (theta < pi/2) * panel_area * solar_constant * cos(theta) * efficiency;
    powers(i) = power;
end

% 그래프 출력
plot(times, powers, 'LineWidth', 1.2);
xlabel('Time (UTC)');
ylabel('Power Output (W)');
title('CubeSat Solar Power Generation');
grid on;

end
