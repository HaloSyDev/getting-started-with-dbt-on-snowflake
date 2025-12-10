
SELECT CURRENT_ROLE();

-- 0. 사용할 웨어하우스
CREATE WAREHOUSE tasty_bytes_dbt_wh WAREHOUSE_SIZE = XLARGE;


-- 1. 통합 및 모델 구체화를 위한 데이터베이스 및 스키마
CREATE DATABASE tasty_bytes_dbt_db;
CREATE SCHEMA tasty_bytes_dbt_db.integrations;
CREATE SCHEMA tasty_bytes_dbt_db.dev;
CREATE SCHEMA tasty_bytes_dbt_db.prod;


-- 2. Snowflake에서 GitHub에 연결하기 위한 API 통합 만들기
-- GitHub와 상호 작용하기 위한 API 통합이 필요
-- 2-1. 시크릿 생성
-- SHOW SECRETS HDC_DATAMART.QS_DATASET;
-- HDC_DATAMART.QS_DATASET.AWS_CODE_COMMIT_SECRET
CREATE OR REPLACE SECRET tasty_bytes_dbt_db.integrations.tb_dbt_git_secret
  TYPE = password
  USERNAME = 'HaloSyDev'
  PASSWORD = 'ghp_your_github_personal_access_token_here';
SHOW SECRETS IN SCHEMA hdc_sandbox.ksy_test_integrations;
drop SECRET tasty_bytes_dbt_db.integrations.tb_dbt_git_secret
;

-- 2-1. INTEGRATION 생성
-- ACCOUNTADMIN만 가능
-- public 레포는 인증 필요 없음
CREATE OR REPLACE API INTEGRATION tb_dbt_git_api_integration
  API_PROVIDER = git_https_api
  API_ALLOWED_PREFIXES = ('https://github.com/HaloSyDev/getting-started-with-dbt-on-snowflake')
  -- Comment out the following line if your forked repository is public
--   ALLOWED_AUTHENTICATION_SECRETS = (tasty_bytes_dbt_db.integrations.tb_dbt_git_secret)
  ENABLED = TRUE;

-- 3. dbt 패지키 다운을 위한 연결
-- Create NETWORK RULE for external access integration
CREATE OR REPLACE NETWORK RULE dbt_network_rule
  MODE = EGRESS
  TYPE = HOST_PORT
  -- Minimal URL allowlist that is required for dbt deps
  VALUE_LIST = (
    'hub.getdbt.com',
    'codeload.github.com'
    );
-- Create EXTERNAL ACCESS INTEGRATION for dbt access to external dbt package locations
CREATE OR REPLACE EXTERNAL ACCESS INTEGRATION dbt_ext_access
  ALLOWED_NETWORK_RULES = (dbt_network_rule)
  ENABLED = TRUE;
-- External access is not supported for trial accounts.
-- ... 젠장..

-- 4. 로컬에서 dbt deps를 먼저 실행한 후 dbt_packages 폴더를 포함해서 배포
-- External Access Integration 없이 dbt 패키지를 사용하는 방법
-- 4-1. dbt 프로젝트 디렉토리로 이동 > 터미널 : dbt deps 실행 > 패키지 다운로드 됨
-- 4-2. snowflake로 배포 (깃으로 해도 되지만, snow cli도 설치 할겸 cli로 해 봄)
pip install snowflake-cli-labs

python -m pip install snowflake-cli-labs

프로젝트 루트로 이동

snow dbt deploy tasty_bytes \
    --source . \
    --profiles-dir . \
    --connection HRMHKZJ-ZW74213

>>  Connection default is not configured  

snow connection list

Default 연결 설정
snow connection set-default HRMHKZJ-ZW74213



-- 5. 프로파일.yml 확인

-- 6. 소스 데이터 설정
-- setup/tasty_bytes_setup.sql 파일에 명령어 샘플 있음
-- 기본 설정
-- CREATE OR REPLACE WAREHOUSE ...;
-- CREATE OR REPLACE API INTEGRATION ...;
-- CREATE OR REPLACE NETWORK RULE ...;
-- CREATE OR REPLACE EXTERNAL ACCESS INTEGRATION ...;
-- 로깅 활성화
-- ALTER SCHEMA tasty_bytes_dbt_db.dev SET LOG_LEVEL = 'INFO';
-- ALTER SCHEMA tasty_bytes_dbt_db.dev SET TRACE_LEVEL = 'ALWAYS';
-- ALTER SCHEMA tasty_bytes_dbt_db.dev SET METRIC_LEVEL = 'ALL';
-- ALTER SCHEMA tasty_bytes_dbt_db.prod SET LOG_LEVEL = 'INFO';
-- ALTER SCHEMA tasty_bytes_dbt_db.prod SET TRACE_LEVEL = 'ALWAYS';
-- ALTER SCHEMA tasty_bytes_dbt_db.prod SET METRIC_LEVEL = 'ALL';

-- 7. deps 명령어 실행
-- 그 전에 로컬에 패키지 다운로드 (4-1 참고)