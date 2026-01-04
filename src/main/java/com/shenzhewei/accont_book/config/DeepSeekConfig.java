package com.shenzhewei.accont_book.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

/**
 * DeepSeek API 配置
 */
@Data
@Configuration
@ConfigurationProperties(prefix = "deepseek.api")
public class DeepSeekConfig {

    /**
     * API Key
     */
    private String key;

    /**
     * API Base URL
     */
    private String baseUrl;

    /**
     * 模型名称
     */
    private String model;

    /**
     * 超时时间（毫秒）
     */
    private Integer timeout;
}
