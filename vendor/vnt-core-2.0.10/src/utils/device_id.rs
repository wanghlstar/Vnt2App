use anyhow::Context;
use std::fs;
use std::path::PathBuf;
pub fn get_device_id() -> anyhow::Result<String> {
    // Android/iOS/tvOS 无法读取稳定的机器标识（machine-uid 在移动端不可用），
    // 直接走 fallback，与 App 通过 Dart 层持久化 device_id 的策略配合
    #[cfg(not(any(target_os = "android", target_os = "ios", target_os = "tvos")))]
    match machine_uid::get() {
        Ok(id) => return Ok(id),
        Err(e) => {
            log::warn!("Failed to get system ID: {}. Using fallback.", e);
        }
    }

    get_fallback_id()
}

/// fallback 设备 ID 文件路径：锚定可执行文件所在目录。
/// 相对路径会随进程 CWD 变化，换目录启动就会读写另一个文件，
/// 导致设备 ID 漂移
fn fallback_id_path() -> PathBuf {
    std::env::current_exe()
        .ok()
        .and_then(|p| p.parent().map(|dir| dir.join("device_id")))
        .unwrap_or_else(|| PathBuf::from("device_id"))
}

fn get_fallback_id() -> anyhow::Result<String> {
    let path = fallback_id_path();

    if let Ok(content) = fs::read_to_string(&path) {
        let id = content.trim();
        if !id.is_empty() {
            return Ok(id.to_string());
        }
    }

    let new_id = uuid::Uuid::new_v4().to_string();

    fs::write(&path, &new_id).context("Failed to write device_id file")?;

    Ok(new_id)
}

#[cfg(test)]
mod tests {
    use super::*;

    /// 路径必须锚定到可执行文件目录（绝对路径），不能是随 CWD 漂移的相对路径
    #[test]
    fn test_fallback_id_path_is_absolute() {
        let path = fallback_id_path();
        assert!(path.is_absolute(), "path should be absolute: {path:?}");
        assert_eq!(path.file_name().unwrap(), "device_id");
    }
}
