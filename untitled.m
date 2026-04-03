%TLT
tle_line1 = '1 52900U 22065G   24233.34741105  .00002524  00000-0  53611-3 0  9992';
tle_line2 = '2 52900  98.1315  12.7117 0006775 314.2572  45.8072 14.59937531113214';

% 초기화
mu = 398600.4418;  % km^3/s^2
solar_constant = 1361;  % W/m^2
panel_area = 0.1 * 0.1;  % m^2
efficiency = 0.25;

% TLE 파싱
[~, satrec] = twoline2rv(tle_line1, tle_line2, 'c', 72);

% 시작 시간: Julian Date
[start_jd, ~] = jday(2024, 8, 20, 0, 0, 0);  % 예시 시점 (TLE 날짜 기준, UTC)

% 시간 범위 (5일 = 7200분, 1분 간격)
minutes = 0:1:(5*24*60);
times = start_jd + minutes / (24*60);

powers = zeros(size(times));

for i = 1:length(times)
    jd = times(i);
    tsince = (jd - satrec.jdsatepoch) * 1440;  % 분 단위
    
    % 위성 위치 계산 (ECI)
    [r_eci, ~] = sgp4(satrec, tsince);
    
    % 태양 위치 계산 (ECI)
    sun_vec = sun_position_eci(jd);

    % 식 현상 확인
    if eclipse_check(r_eci, sun_vec)
        powers(i) = 0;
        continue;
    end

    % 자세: 연세대(지구) 향하는 방향을 -Z, 태양전지판은 이에 수직한 면 중 태양 쪽으로 가장 가까운 방향
    z_body = -r_eci / norm(r_eci);
    sun_unit = sun_vec / norm(sun_vec);
    
    % 이상적인 전지판 방향: 태양 방향을 projection 해서 선택
    x_body_candidate = cross([0 0 1], z_body);
    if norm(x_body_candidate) < 1e-6
        x_body_candidate = cross([1 0 0], z_body);
    end
    x_body = x_body_candidate / norm(x_body_candidate);
    y_body = cross(z_body, x_body);
    
    % 가장 태양을 잘 보는 면: x, -x, y, -y 중 태양과 가장 작은 각도
    candidates = [x_body; -x_body; y_body; -y_body];
    best_dot = -1;
    for j = 1:4
        d = dot(candidates(j, :), sun_unit);
        if d > best_dot
            best_dot = d;
        end
    end
    
    incidence_angle = acos(best_dot);
    if incidence_angle < pi/2
        powers(i) = panel_area * solar_constant * cos(incidence_angle) * efficiency;
    else
        powers(i) = 0;
    end
end

% 그래프
datetime_array = datetime(times, 'ConvertFrom', 'juliandate');
plot(datetime_array, powers, 'LineWidth', 1.2);
xlabel('Time (UTC)'); ylabel('Power Output (W)');
title('Solar Power Generation Over 5 Days');
grid on;
