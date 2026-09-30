import 'package:flutter_test/flutter_test.dart';
import 'package:vnt2_app/data_persistence.dart';
import 'package:vnt2_app/network_config.dart';

NetworkConfig _buildConfig({
  required String itemKey,
  required String configName,
  required String deviceId,
  String virtualIp = '',
}) {
  return NetworkConfig(
    itemKey: itemKey,
    configName: configName,
    token: 'group-1',
    deviceName: 'desktop-node',
    virtualIPv4: virtualIp,
    serverList: const ['quic://127.0.0.1:2225'],
    groupPassword: '',
    deviceID: deviceId,
    virtualNetworkCardName: 'vnt-tun',
    mtu: 1410,
  );
}

void main() {
  group('Windows runtime identity ownership', () {
    test('Windows 身份注册目录标识应使用 Vnt2App', () {
      expect(
        DataPersistence.windowsIdentityRegistryAppDirectoryName,
        'Vnt2App',
      );
    });

    test('无注册标记且带有旧唯一身份时应触发旋转', () {
      final configs = [
        _buildConfig(
          itemKey: 'cfg-1',
          configName: '主配置',
          deviceId: 'legacy-device-id',
        ),
      ];

      final shouldRotate =
          DataPersistence.shouldRotateWindowsIdentityForCopiedRuntime(
        uniqueId: 'legacy-unique-id',
        configs: configs,
        hasRegistrationMarker: false,
      );

      expect(shouldRotate, isTrue);
    });

    test('已有注册标记时不应重复旋转', () {
      final configs = [
        _buildConfig(
          itemKey: 'cfg-1',
          configName: '主配置',
          deviceId: 'legacy-device-id',
        ),
      ];

      final shouldRotate =
          DataPersistence.shouldRotateWindowsIdentityForCopiedRuntime(
        uniqueId: 'legacy-unique-id',
        configs: configs,
        hasRegistrationMarker: true,
      );

      expect(shouldRotate, isFalse);
    });

    test('旋转后所有配置共享新的设备ID', () {
      final configs = [
        _buildConfig(
          itemKey: 'cfg-1',
          configName: '主配置',
          deviceId: 'legacy-1',
        ),
        _buildConfig(
          itemKey: 'cfg-2',
          configName: '备用配置',
          deviceId: 'legacy-2',
          virtualIp: '10.10.10.10',
        ),
      ];

      final rotated = DataPersistence.rebuildNetworkConfigsWithUniqueId(
        configs,
        'next-device-id',
      );

      expect(
        rotated.map((config) => config.deviceID).toSet(),
        {'next-device-id'},
      );
      expect(rotated[1].virtualIPv4, '10.10.10.10');
    });

    test('旋转不应覆盖用户自定义的设备ID', () {
      final configs = [
        _buildConfig(
          itemKey: 'cfg-1',
          configName: '主配置',
          deviceId: 'legacy-unique-id',
        ),
        _buildConfig(
          itemKey: 'cfg-2',
          configName: '自定义配置',
          deviceId: 'my-device-01',
          virtualIp: '10.10.10.10',
        ),
      ];

      final rotated = DataPersistence.rebuildNetworkConfigsWithUniqueId(
        configs,
        'next-device-id',
        previousUniqueId: 'legacy-unique-id',
      );

      // 仍等于上一个安装级身份的被替换，自定义值原样保留
      expect(rotated[0].deviceID, 'next-device-id');
      expect(rotated[1].deviceID, 'my-device-01');
      expect(rotated[1].virtualIPv4, '10.10.10.10');
    });

    test('空设备ID在旋转时也会被填充', () {
      final configs = [
        _buildConfig(
          itemKey: 'cfg-1',
          configName: '主配置',
          deviceId: '',
        ),
      ];

      final rotated = DataPersistence.rebuildNetworkConfigsWithUniqueId(
        configs,
        'next-device-id',
        previousUniqueId: 'legacy-unique-id',
      );

      expect(rotated[0].deviceID, 'next-device-id');
    });
  });
}
