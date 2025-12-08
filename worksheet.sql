
SELECT CURRENT_ROLE();

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
-- 4-1. dbt 프로젝트 디렉토리로 이동 > 패키지 다운로드



