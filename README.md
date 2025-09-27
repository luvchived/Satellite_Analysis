# Satellite_Analysis

-추출 데이터

위성의 AOS(acquisition of signal), LOS(Loss of signal), Max elevation 추출하기 
AOS: 위성이 지평선 위로 처음 떠오르기 시작하는 시각
LOS: 위성이 지평선 아래로 사라지는 시각
Max Elevation: 위성의 고도가 가장 높은 시점
​
​<img width="242" height="144" alt="스크린샷 2025-09-27 오후 12 39 14" src="https://github.com/user-attachments/assets/e4169b65-b509-4c8b-bf15-d126ff241275" />



-Python implementation of the SGP4 algorithm for satellite orbit propagation

-Simplified General Perturbations
​  5가지의 모델 존재
  ->SGP, ***SGP4***, SDP4, SGP8, SDP8
​  :인공위성 등의 궤도 위치 및 속도를 ECI 기준으로 계산하는 알고리즘

- Need
  1. TLE(Two-Line Element set)
    Get TLE data: https://celestrak.org/NORAD/elements/gp.php?GROUP=active&FORMAT=tle
  2. Matlab R2025a
  3. SGP4 tools: https://www.mathworks.com/matlabcentral/fileexchange/62013-sgp4
     함수 들어가서 ecef2tod, Mjday, sgp4 다운
