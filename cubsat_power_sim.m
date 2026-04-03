% MATLAB Code: CubeSat Solar Power Simulation using satelliteScenario API
% Requirements: Aerospace Toolbox (satelliteScenario, satellite, states, etc.)

% ---------- CONFIG ----------
tle1 = "1 52900U 22065G   24233.34741105  .00002524  00000-0  53611-3 0  9992";
tle2 = "2 52900  98.1315  12.7117 0006775 314.2572  45.8072 14.59937531113214";
sim_start = datetime(2024, 8, 20, 0, 0, 0);  % UTC 시작 시각
sim_end = sim_start + days(5);  % 5일 후
step = minutes(1);  % 1분 간격

% ---------- SETUP ----------
sc = satelliteScenario(sim_start, sim_end, seconds(60));
sat = satellite(sc, tle1, tle2);

% 연세대 지상국 위치
lat = 37.5; lon = 126.9; alt = 0.1;  % km 단위
gs = groundStation(sc, lat, lon, alt);

% 시간 벡터
times = sim_start:step:sim_end;
n = length(times);

% 출력 초기화
powers = zeros(1, n);

% 위성 파라미터
panel_area = 0.01;  % m^2
solar_constant = 1361;  % W/m^2
efficiency = 0.25;
Re = 6378.137;  % 지구 반지름 [km]

% ---------- SIMULATION ----------
for i = 1:n
    t = times(i);

    % 위성 위치 (ECI)
    r = states(sat, t, 'CoordinateFrame', 'inertial');
    r = r(1:3);  % 위치만 추출

    % 태양 위치 (ECI)
    jd = juliandate(t);
    sun_vec = sun_position_eci(jd);

    % Eclipse 판별
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

    % 자세 가정: -z 방향이 지구 향함, x/y축에서 태양과 가장 일치하는 방향을 태양전지판 방향으로 선택
    z_body = -r / norm(r);
    x_cand = cross([0 0 1], z_body);
    if norm(x_cand) < 1e-6
        x_cand = cross([1 0 0], z_body);
    end
    x_body = x_cand / norm(x_cand);
    y_body = cross(z_body, x_body);

    sun_unit = sun_vec / norm(sun_vec);
    candidates = [x_body; -x_body; y_body; -y_body];
    best_dot = -1;
    for j = 1:4
        d = dot(candidates(j, :), sun_unit);
        if d > best_dot
            best_dot = d;
        end
    end

    theta = acos(best_dot);
    if theta < pi/2
        power = panel_area * solar_constant * cos(theta) * efficiency;
    else
        power = 0;
    end
    powers(i) = power;
end

% ---------- PLOT ----------
plot(times, powers, 'LineWidth', 1.2);
xlabel('Time (UTC)');
ylabel('Power Output (W)');
title('CubeSat Solar Power Generation Over 5 Days');
grid on;
