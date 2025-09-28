clear; clc;

% 연세대 지상국
gs_lat = 37.5;
gs_lon = 126.9;
gs_alt = 100;

tle1 = '1 52900U 22065G   24233.34741105  .00002524  00000-0  53611-3 0  9992';
tle2 = '2 52900  98.1315  12.7117 0006775 314.2572  45.8072 14.59937531113214';

% 시작 시각 (UTC)
start_time = datetime(2024,8,22,8,20,0,'TimeZone','UTC');
end_time = start_time + hours(120);  % 5일

% 시간 벡터 생성 (10초 간격)
time_vec = start_time:seconds(10):end_time;

% SGP4 초기화
satrec = twoline2rv(tle1, tle2, 'c');

% 결과 저장
pass_list = [];
in_pass = false;

fprintf('=== MIMAN 위성 패스 예측 (UTC 기준) ===\n');

for i = 1:length(time_vec)
    t = time_vec(i);
    [jd, fr] = jday(t.Year, t.Month, t.Day, t.Hour, t.Minute, t.Second);
    [e, r_eci, v] = sgp4(satrec, (jd + fr - satrec.jdsatepoch) * 1440);

    if e ~= 0
        continue;
    end

    % ECI -> AZ/EL 변환
    [az, el, ~] = eci2azel(r_eci*1000, t, gs_lat, gs_lon, gs_alt);

    if el >= 0
        if ~in_pass
            pass.AOS = t;
            pass.maxEl = el;
            in_pass = true;
        else
            pass.maxEl = max(pass.maxEl, el);
        end
    elseif in_pass
        pass.LOS = t;
        pass_list = [pass_list; pass];
        in_pass = false;
    end
end

for i = 1:length(pass_list)
    aos_kst = datetime(pass_list(i).AOS,'TimeZone','Asia/Seoul');
    los_kst = datetime(pass_list(i).LOS,'TimeZone','Asia/Seoul');
    max_el = pass_list(i).maxEl;
    fprintf('%2d) AOS: %s | LOS: %s | Max Elev: %.1f°\n', ...
        i, datestr(aos_kst), datestr(los_kst), max_el);
end

animation(time_vec, satrec);
