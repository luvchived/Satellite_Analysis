% SGP4
addpath(genpath(pwd));
addpath(genpath('/Users/jsksk/Downloads/SGP4_2/SGP4'));

% TLE 문자열
tle = [
  "1 52900U 22065G   24233.34741105  .00002524  00000-0  53611-3 0  9992";
  "2 52900  98.1315  12.7117 0006775 314.2572  45.8072 14.59937531113214"
];

% 시뮬레이션 시간 설정
start_time = datetime(2024, 8, 20, 0, 0, 0) + hours(9); % KST
duration_days = 5;
sim_start = start_time;
sim_end = sim_start + days(duration_days);
step = minutes(1);

% 시나리오 객체 및 위성, 지상국 설정
sc = satelliteScenario(sim_start, sim_end, 60);
sat = satellite(sc, char(tle));
gs = groundStation(sc, ...
    "Latitude", 37.5, ...
    "Longitude", 126.9, ...
    "Altitude", 0.1);  % 연세대

% 시간 벡터
times = sim_start:step:sim_end;
n = length(times);
powers = zeros(1, n);

% 파라미터
panel_area = 0.01;
solar_constant = 1361;
efficiency = 0.25;
Re = 6378.137;  % 지구 반지름 [km]

for i = 1:n
    t = times(i);
    r = states(sat, t, 'CoordinateFrame', 'inertial');
    r = r(1:3).';  % 열벡터 → 행벡터

    jd = juliandate(t);
    sun_vec = sun_position_eci(jd).';  % 열벡터 → 행벡터

    sat_to_sun = sun_vec - r;
    sat_to_sun_unit = sat_to_sun / norm(sat_to_sun);
    dot_prod = dot(r, sat_to_sun_unit);

    % 식 현상 판단
    closest = r - dot_prod * sat_to_sun_unit;
    dist = norm(closest);
    in_eclipse = (dot_prod > 0) && (dist < Re);
    if in_eclipse
        powers(i) = 0;
        continue;
    end

    % attitude 가정
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

% 결과 출력
plot(times, powers, 'LineWidth', 1.2);
xlabel('Time (KST)');
ylabel('Power Output (W)');
title('CubeSat Solar Power Generation');
grid on;

%% 태양 위치 함수
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
