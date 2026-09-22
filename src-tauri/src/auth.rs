use serde::{Deserialize, Serialize};

const PLATFORM_BASE_URL: &str = "https://api.tayyem.dev";
const REQUIRED_SERVICE: &str = "vpn-access";

#[derive(Deserialize)]
struct ServiceInfo {
    key: String,
}

#[derive(Deserialize)]
struct UserResponse {
    username: String,
    email: Option<String>,
    #[serde(rename = "mustChangePassword")]
    must_change_password: bool,
    #[serde(rename = "emailVerified")]
    email_verified: bool,
    services: Vec<ServiceInfo>,
}

#[derive(Deserialize)]
struct LoginResponse {
    #[serde(rename = "accessToken")]
    access_token: String,
    #[serde(rename = "refreshToken")]
    refresh_token: String,
    user: UserResponse,
}

#[derive(Deserialize)]
struct ApiError {
    message: Option<String>,
}

#[derive(Serialize)]
pub struct LoginOutcome {
    pub ok: bool,
    pub error: Option<String>,
    pub username: Option<String>,
    pub email: Option<String>,
    pub access_token: Option<String>,
    pub refresh_token: Option<String>,
}

pub async fn login(username_or_email: &str, password: &str) -> LoginOutcome {
    let client = reqwest::Client::new();
    let resp = client
        .post(format!("{PLATFORM_BASE_URL}/api/auth/login"))
        .json(&serde_json::json!({
            "usernameOrEmail": username_or_email,
            "password": password,
        }))
        .send()
        .await;

    let resp = match resp {
        Ok(r) => r,
        Err(e) => {
            return LoginOutcome {
                ok: false,
                error: Some(format!("Could not reach the platform: {e}")),
                username: None,
                email: None,
                access_token: None,
                refresh_token: None,
            }
        }
    };

    if !resp.status().is_success() {
        let message = resp
            .json::<ApiError>()
            .await
            .ok()
            .and_then(|e| e.message)
            .unwrap_or_else(|| "Invalid username/email or password".to_string());
        return LoginOutcome {
            ok: false,
            error: Some(message),
            username: None,
            email: None,
            access_token: None,
            refresh_token: None,
        };
    }

    let body = match resp.json::<LoginResponse>().await {
        Ok(b) => b,
        Err(e) => {
            return LoginOutcome {
                ok: false,
                error: Some(format!("Unexpected response from platform: {e}")),
                username: None,
                email: None,
                access_token: None,
                refresh_token: None,
            }
        }
    };

    if body.user.must_change_password {
        return LoginOutcome {
            ok: false,
            error: Some("Finish setting up your account at myaccount.tayyem.dev first.".into()),
            username: None,
            email: None,
            access_token: None,
            refresh_token: None,
        };
    }
    if !body.user.email_verified {
        return LoginOutcome {
            ok: false,
            error: Some("Confirm your email at myaccount.tayyem.dev before using the VPN.".into()),
            username: None,
            email: None,
            access_token: None,
            refresh_token: None,
        };
    }
    if !body.user.services.iter().any(|s| s.key == REQUIRED_SERVICE) {
        return LoginOutcome {
            ok: false,
            error: Some("This account does not have VPN access. Contact an admin.".into()),
            username: None,
            email: None,
            access_token: None,
            refresh_token: None,
        };
    }

    LoginOutcome {
        ok: true,
        error: None,
        username: Some(body.user.username),
        email: body.user.email,
        access_token: Some(body.access_token),
        refresh_token: Some(body.refresh_token),
    }
}
