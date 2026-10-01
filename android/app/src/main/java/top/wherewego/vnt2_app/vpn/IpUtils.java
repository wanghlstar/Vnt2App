package top.wherewego.vnt2_app.vpn;

/**
 * ip转换
 *
 * @author https://github.com/lbl8603/vnt
 */
public class IpUtils {
    /**
     * 将整数的ip地址转成字符串，例如 0 转成 "0.0.0.0"
     *
     * @param ipAddress
     * @return
     */
    public static String intToIpAddress(int ipAddress) {

        return ((ipAddress & 0xFF000000) >>> 24) + "." +
                ((ipAddress & 0x00FF0000) >>> 16) + "." +
                ((ipAddress & 0x0000FF00) >>> 8) + "." +
                (ipAddress & 0x000000FF);
    }
    public static int ipToInt(String ipAddress) {
        if (ipAddress == null || ipAddress.trim().isEmpty()) {
            // 空值（如核心未下发网关）不能抛异常，否则整个建连流程会被打断
            return 0;
        }
        String[] parts = ipAddress.split("\\.");
        if (parts.length != 4) {
            return 0;
        }
        int ip = 0;
        for (int i = 0; i < 4; i++) {
            ip <<= 8;
            try {
                int part = Integer.parseInt(parts[i]);
                if (part < 0 || part > 255) {
                    return 0;
                }
                ip |= part;
            } catch (NumberFormatException e) {
                return 0;
            }
        }
        return ip;
    }

    /**
     * 返回掩码的长度
     *
     * @param subnetMask
     * @return
     */
    public static int subnetMaskToPrefixLength(int subnetMask) {
        int prefixLength = 0;
        int bit = 1 << 31;

        while (subnetMask != 0) {
            if ((subnetMask & bit) != bit) {
                break;
            }
            prefixLength++;
            subnetMask <<= 1;
        }

        return prefixLength;
    }
}