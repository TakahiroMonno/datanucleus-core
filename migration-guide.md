Title: Migrating from Log4j 1 :: Apache Log4j

URL Source: https://logging.apache.org/log4j/2.x/migrate-from-log4j1.html

Published Time: Sat, 28 Mar 2026 11:05:44 GMT

Markdown Content:
[Log4j 1](http://logging.apache.org/log4j/1.x) has [reached End of Life](https://news.apache.org/foundation/entry/apache_logging_services_project_announces) in 2015, and is no longer supported. Vulnerabilities reported after August 2015 against Log4j 1 are not checked and will not be fixed. Users should [upgrade to Log4j 2](https://logging.apache.org/log4j/2.x/migrate-from-log4j1.html#) to obtain security fixes.

Since Log4j 2 has been rewritten from scratch, it introduces many breaking changes to its predecessor. Most notably:

*   It uses a new package namespace (`org.apache.logging.log4j`), whereas Log4j 1 used the `org.apache.log4j` namespace,

*   It features a [logging API](https://logging.apache.org/log4j/2.x/manual/api.html) which is independent of its reference implementation,

*   It uses a new more flexible [configuration file format](https://logging.apache.org/log4j/2.x/manual/configuration.html), which is **incompatible** with the format used by Log4j 1.

## [](https://logging.apache.org/log4j/2.x/migrate-from-log4j1.html#prepare-to-migrate)Prepare to migrate

Are you a library developer?

If you are developing a library, which functionality is not related to logging, you only need to rewrite the library to use Log4j 2 API. Skip directly to [Log4j 1 API migration](https://logging.apache.org/log4j/2.x/migrate-from-log4j1.html#api-migration).

In order to migrate your application to Log4j 2 you need to assess first how your application **and** its dependencies use Log4j 1. While Log4j 1 didn’t have a formal split between a logging API and a logging backend, for the purpose of this guide, we’ll introduce the following split:

Log4j 1 API
It is the part of the Log4j 1 library that produces log events, and it is the most commonly used. The methods that are considered part of the Log4j 1 API are listed below:

Table 1. Log4j 1 API methods
| Class name | Methods |
| --- | --- |
| `org.apache.log4j.MDC` | All methods |
| `org.apache.log4j.NDC` | All methods |
| `org.apache.log4j.Priority` | All methods |
| `org.apache.log4j.Level` | All methods |
| `org.apache.log4j.Category` | All methods, except: methods for the [AppenderAttachable](https://logging.apache.org/log4j/1.x/apidocs/org/apache/log4j/spi/AppenderAttachable.html) interface, `callsAppenders` and `setLevel`. |
| `org.apache.log4j.Logger` | Same as `Category` |
| `org.apache.log4j.LogManager` | All methods |
Log4j 1 Backend
This is the part of the logging library that consumes log events, formats them and writes to their destination. It also allows to configure Log4j 1 programmatically. It is usually **not used** in code, since the recommended way to configure Log4j 1 is through a configuration file.

While it is fairly simple to check which classes and methods in the `org.apache.log4j` package are used by your own application, the task is much more complex, when it comes to your application dependencies.

All the libraries that use **Log4j 1 API** in their code must have a compile dependency on either [log4j:log4j](https://central.sonatype.com/artifact/log4j/log4j) or its clone [ch.qos.reload4j:reload4j](https://central.sonatype.com/artifact/ch.qos.reload4j/reload4j). There are however misconfigured libraries that declare those dependencies, even if they don’t directly use Log4j 1 **at all**.

To distinguish between libraries that use Log4j 1 and those that don’t, you can look for the presence of other logging APIs. If a library **directly** depends on:

*   [`commons-logging:commons-logging`](https://central.sonatype.com/artifact/commons-logging/commons-logging),

*   [`org.apache.logging.log4j:log4j-api`](https://central.sonatype.com/artifact/org.apache.logging.log4j/log4j-api),

*   [`org.slf4j:slf4j-api`](https://central.sonatype.com/artifact/org.slf4j/slf4j-api),

*   [`jboss-logging`](https://central.sonatype.com/artifact/org.jboss.logging/jboss-logging),

*   other logging APIs,

it is fair to assume that it uses those libraries **instead** of **Log4j 1 API**, even if it has a direct dependency on `log4j:log4j` or `ch.qos.reload4j:reload4j`.

The following sections explain how to migrate from Log4j 1 to Log4j 2, depending on the way Log4j 1 is used in your application:

*   if your application or one of its dependencies is coded against Log4j 1 API, see [Log4j 1 API migration](https://logging.apache.org/log4j/2.x/migrate-from-log4j1.html#api-migration),

*   if your application uses Log4j 1 only as logging backend, see [Log4j 1 Backend migration](https://logging.apache.org/log4j/2.x/migrate-from-log4j1.html#backend-migration).

## [](https://logging.apache.org/log4j/2.x/migrate-from-log4j1.html#api-migration)Log4j 1 API migration

To migrate an application that uses Log4j 1 API as logging API, the recommended approach is to modify your code. See [Migrate code from Log4j 1 API to Log4j 2 API](https://logging.apache.org/log4j/2.x/migrate-from-log4j1.html#api-code-migration) for details.

In the case one of your libraries uses Log4j 1 API or you can not modify your logging code at the moment, a Log4j 1 to Log4j 2 bridge is available. See [Use Log4j 1 to Log4j 2 API bridge](https://logging.apache.org/log4j/2.x/migrate-from-log4j1.html#api-use-bridge) for details.

### [](https://logging.apache.org/log4j/2.x/migrate-from-log4j1.html#api-code-migration)Migrate code from Log4j 1 API to Log4j 2 API

You can migrate your code from Log4j 1 to Log4j 2 automatically, by using the [Log4j1ToLog4j2](https://docs.openrewrite.org/recipes/java/logging/log4j/log4j1tolog4j2) OpenRewrite recipe. See [OpenRewrite site](https://docs.openrewrite.org/recipes/java/logging/log4j/log4j1tolog4j2) for more details.

Except the change in the package name from `org.apache.log4j` to `org.apache.logging.log4j`, most of the class and method names in Log4j 2 API are inherited from Log4j 1 API.

In order to migrate you code, you need to:

*   modify the imports and types used by your application, according to the following table:

Table 2. Migration of types from Log4j 1 to Log4j 2
| Migrate Log4j 1 type | to Log4j type |
| --- | --- |
| `org.apache.log4j.MDC` | `org.apache.logging.log4j.ThreadContext` |
| `org.apache.log4j.NDC` | `org.apache.logging.log4j.ThreadContext` |
| `org.apache.log4j.Priority` | `org.apache.logging.log4j.Level` |
| `org.apache.log4j.Level` | `org.apache.logging.log4j.Level` |
| `org.apache.log4j.Category` | `org.apache.logging.log4j.Logger` |
| `org.apache.log4j.Logger` | `org.apache.logging.log4j.Logger` |
| `org.apache.log4j.LogManager` | `org.apache.logging.log4j.LogManager` |
*   Some Log4j 1 methods were renamed or moved to a different class. Therefore, you need to replace the following methods with their Log4j 2 API equivalents:

Table 3. Migration of methods from Log4j 1 to Log4j 2
| Migrate Log4j 1 method | to Log4j method |
| --- | --- |
| `Logger.getLogger()` | `LogManager.getLogger()` |
| `Logger.getRootLogger()` | `LogManager.getRootLogger()` |
| `Category.getEffectiveLevel()` | `Logger.getLevel()` |
*   Finally, some methods need specific conversion rules to be applied:

Table 4. Special Log4j 1 method migration rules
| Method | Description |
| --- | --- |
| [`Logger.getLogger(String, LoggerFactory)`](https://logging.apache.org/log4j/1.x/apidocs/org/apache/log4j/Logger.html#getLogger(java.lang.String,%20org.apache.log4j.spi.LoggerFactory)) | Remove the `LoggerFactory` parameter and use one of Log4j 2’s other extension mechanisms. |
| [`LogManager.shutdown()`](https://logging.apache.org/log4j/1.x/apidocs/org/apache/log4j/LogManager.html#shutdown()) | Since Log4j 2.6, an equivalent [`o.a.l.l.LogManager.shutdown()`](https://logging.apache.org/log4j/2.x/javadoc/log4j-api/org/apache/logging/log4j/LogManager.html#shutdown()) method can be used. The utility of this method call depends upon the logging backend used with Log4j API. The Log4j Core backend automatically adds a JVM shutdown hook on start up to perform any cleanups, so the `LogManager.shutdown()` call can be safely removed. Starting in Log4j 2.1, you can also specify a custom [ShutdownCallbackRegistry](https://logging.apache.org/log4j/2.x/javadoc/log4j-core/org/apache/logging/log4j/core/util/ShutdownCallbackRegistry.html). See [log4j2.shutdownCallbackRegistry](https://logging.apache.org/log4j/2.x/manual/systemproperties.html#log4j2.shutdownCallbackRegistry) for more details. |
| Non Log4j 1 API methods | Methods outside of those listed in [[log4j-1-api-methods]](https://logging.apache.org/log4j/2.x/migrate-from-log4j1.html#log4j-1-api-methods), such as `Logger.setLevel()` need to be replaced with a method call specific to the logging backend used by the application. Some third-party integrators, such as Spring Boot, provide utility methods that let you abstract the logging backend, e.g. the [`LoggingSystem.setLogLevel()`](https://docs.spring.io/spring-boot/api/java/org/springframework/boot/logging/LoggingSystem.html#setLogLevel(java.lang.String,org.springframework.boot.logging.LogLevel)) Spring Boot method. |

To prevent a performance penalty from string concatenation in disabled log statements, Log4j 1 required the use of `is*Enabled()` guards:

```
if (LOGGER.isInfoEnabled()) {
    LOGGER.info("Hello " + username + "!");
}
```

java

Since Log4j 2 API introduces [parameterized logging](https://logging.apache.org/log4j/2.x/manual/api.html#best-practice-concat) these guards are no longer necessary and the same statement can be rewritten as:

`LOGGER.info("Hello {}!", username);`
java

### [](https://logging.apache.org/log4j/2.x/migrate-from-log4j1.html#api-use-bridge)[](https://logging.apache.org/log4j/2.x/migrate-from-log4j1.html)Use Log4j 1 to Log4j 2 API bridge

If you can not modify your application’s code or one of your dependencies is using [Log4j 1 API](https://logging.apache.org/log4j/2.x/migrate-from-log4j1.html#log4j-1-api-methods) as logging API, you can delay the migration process by [installing the Log4j 1 to Log4j 2 bridge](https://logging.apache.org/log4j/2.x/migrate-from-log4j1.html#log4j-1-2-api-installation).

Since forwarding Log4j 1 API calls to Log4j 2 API calls is the basic functionality of the bridge, no further configuration is required from your part.

## [](https://logging.apache.org/log4j/2.x/migrate-from-log4j1.html#backend-migration)Log4j 1 Backend migration

If your application uses Log4j 1 **only** as logging backend bound to another logging API, such as Apache Commons Logging (JCL) or SLF4J, you only need to:

1.   Configure all logging bridges to log to Log4j 2 API instead. This can be done by replacing the following dependencies on your application’s runtime classpath:

Table 5. Dependency migration from Log4j 1 to Log4j 2
| Replace Log4j 1 dependency | with Log4j 2 dependency |
| --- | --- |
| [`log4j:log4j`](https://central.sonatype.com/artifact/log4j/log4j) | [`org.apache.logging.log4j:log4j-core`](https://central.sonatype.com/artifact/org.apache.logging.log4j/log4j-core) |
| [`ch.qos.reload4j:reload4j`](https://central.sonatype.com/artifact/ch.qos.reload4j/reload4j) | [`org.apache.logging.log4j:log4j-core`](https://central.sonatype.com/artifact/org.apache.logging.log4j/log4j-core) |
| [`commons-logging:commons-logging`](https://central.sonatype.com/artifact/commons-logging/commons-logging) | either upgrade to version 1.3.0 (or later) or replace with [`org.apache.logging.log4j:log4j-jcl`](https://central.sonatype.com/artifact/org.apache.logging.log4j/log4j-slf4j2-impl) |
| [`org.slf4j:slf4j-log4j12`](https://central.sonatype.com/artifact/org.slf4j/slf4j-log4j12) | [`org.apache.logging.log4j:log4j-slf4j2-impl`](https://central.sonatype.com/artifact/org.apache.logging.log4j/log4j-slf4j2-impl) |
| [`org.slf4j:slf4j-reload4j`](https://central.sonatype.com/artifact/org.slf4j/slf4j-reload4j) | [`org.apache.logging.log4j:log4j-slf4j2-impl`](https://central.sonatype.com/artifact/org.apache.logging.log4j/log4j-slf4j2-impl) |
2.   Convert your configuration files from the Log4j 1 to the Log4j 2 configuration format. See [Log4j 1 Configuration file migration](https://logging.apache.org/log4j/2.x/migrate-from-log4j1.html#configuration-file-migration) below for more details.

### [](https://logging.apache.org/log4j/2.x/migrate-from-log4j1.html#migrate-custom-components)Migrate Log4j 1 custom components

Since Log4j 1 offered a limited amount of appenders and layouts, over the years users implemented many **custom** components that offered additional features. If you are currently using a custom Log4j 1 component you should proceed as follows:

1.   Log4j 2 provides many improvements to Log4j 1 components and many new components. Check if the feature offered by your custom component is not already available in Log4j 2. If you can not find the feature, ask on our [support channels](https://logging.apache.org/support.html).

2.   Since Log4j 2.17.2, the Log4j 1 to Log4j 2 bridge has a limited support for using native Log4j 1 appenders and layouts. Native Log4j 1 components can only be configured using Log4j 1 configuration files (see [Use Log4j 1 to Log4j 2 bridge](https://logging.apache.org/log4j/2.x/migrate-from-log4j1.html#ConfigurationCompatibility)) and require the [installation of the Log4j 1 to Log4j 2 bridge](https://logging.apache.org/log4j/2.x/migrate-from-log4j1.html#log4j-1-2-api-installation).

Mixing Log4j 1 and Log4j 2 components will most certainly reduce the performance of the logging system. 
3.   If your Log4j 1 native component is not supported by the Log4j 1 to Log4j 2 bridge, we suggest to rewrite it directly as Log4j 2 component. See [Extending](https://logging.apache.org/log4j/2.x/manual/extending.html) for more details.

## [](https://logging.apache.org/log4j/2.x/migrate-from-log4j1.html#configuration-file-migration)Log4j 1 Configuration file migration

### [](https://logging.apache.org/log4j/2.x/migrate-from-log4j1.html#Log4j2ConfigurationFormat)Convert configuration file from Log4j 1 to Log4j 2

Although the Log4j 2 configuration syntax is different from that of Log4j 1, most, if not all, of the same functionality is available.

The `log4j-1.2-api` bridge contains a small utility that converts `log4j.properties` files into `log4j2.xml` file. In order to use it you need to:

1.   Download the `log4j-api`, `log4j-core` and `log4j-1.2-api` artifacts. To retrieve them all at once, see the [Download](https://logging.apache.org/log4j/2.x/download.html) page.

2.   Set the `CLASSPATH` environment variable to contain the artifacts mentioned above.

3.   Run

```
java org.apache.log4j.config.Log4j1ConfigurationConverter \
  --in log4j.properties --out log4j2.xml
```

shell

#### [](https://logging.apache.org/log4j/2.x/migrate-from-log4j1.html#configuration-interpolation)Interpolation

Log4j 1 only supports interpolation using system properties and properties from the `log4j.properties` file using the `${foo}` syntax. Log4j 2 extended this mechanism, by introducing pluggable [Lookups](https://logging.apache.org/log4j/2.x/manual/lookups.html).

In order to convert a Log4j 1 configuration file that uses interpolation to a Log4j 2 configuration file, replace all occurrences of `${foo}` with `${sys:foo}`.

#### [](https://logging.apache.org/log4j/2.x/migrate-from-log4j1.html#configuration-appenders)Appenders

Log4j 2 contains an equivalent for most Log4j 1 appenders:

Table 6. Log4j 2 equivalents of Log4j 1 appenders
| Log4j 1 appender | Log4j 2 equivalent | Notes |
| --- | --- | --- |
| `org.apache.log4j.AsyncAppender` | `Async` |  |
| `org.apache.log4j.ConsoleAppender` | `Console` |  |
| `org.apache.log4j.DailyRollingFileAppender` | `RollingFile` | See [additional steps below](https://logging.apache.org/log4j/2.x/migrate-from-log4j1.html#rolling-file-conversion). |
| `org.apache.log4j.FileAppender` | `File` |  |
| `org.apache.log4j.RollingFileAppender` | `RollingFile` | See [additional steps below](https://logging.apache.org/log4j/2.x/migrate-from-log4j1.html#rolling-file-conversion). |
| `org.apache.log4j.jdbc.JDBCAppender` | `JDBC` |  |
| `org.apache.log4j.net.JMSAppender` | `JMS` |  |
| `org.apache.log4j.net.SocketAppender` | `Socket` |  |
| `org.apache.log4j.net.SMTPAppender` | `SMTP` |  |
| `org.apache.log4j.net.SyslogAppender` | `Syslog` | Does not support custom layouts. |
| `org.apache.log4j.rewrite.RewriteAppender` | `Rewrite` |  |

*   Log4j 2 by default uses a different strategy to determine the index of the archived log files. Log4j 1 always rolls the current log file (e.g. `app.log`) to a log file with index `1` (e.g. `app.log.1`). Log4j 2 on the other hand uses the first available index (e.g. `app.log.42` if files `app.log.1` thru `app.log.41` already exist).

To use the same algorithm to determine the index of the logged file in Log4j 1 and Log4j 2, you need to configure the `fileIndex` attribute of the [default rollover strategy](https://logging.apache.org/log4j/2.x/manual/appenders/rolling-file.html#DefaultRolloverStrategy) to `min`.

`<DefaultRolloverStrategy fileIndex="min"/>`
xml 
*   The two rolling file appenders available in Log4j 1, use an implicit file pattern and triggering policy for the archived log files. If the current log file is called `app.log`, you need to configure the Log4j 2 rolling file appender with the following `filePattern` and triggering policy configuration options:

Table 7. Rolling file appender conversion
| Log4j 1 appender | Log4j 2 `filePattern` | Log4j 2 triggering policy |
| --- | --- | --- |
| `org.apache.log4j.DailyRollingFileAppender` | `app.%d{YYYY-MM-dd}` | `TimeBasedTriggeringPolicy` |
| `org.apache.log4j.RollingFileAppender` | `app.%i` | `SizeBasedTriggeringPolicy` |

#### [](https://logging.apache.org/log4j/2.x/migrate-from-log4j1.html#configuration-layouts)Layouts

Log4j 1 layouts can be converted to Log4j 2 layouts using the following conversion rules:

The formatting of the `%p` (when used with custom levels), `%x` and `%X` pattern converters slightly changed between Log4j 1 and Log4j 2. If an exact backward compatibility is required, you need to [install the Log4j 1 to Log4j 2 bridge](https://logging.apache.org/log4j/2.x/migrate-from-log4j1.html#log4j-1-2-api-installation) and use the following extended patterns:

| Log4j 1 pattern | Log4j 1 to Log4j 2 bridge pattern |
| --- | --- |
| `%p` | `%v1Level` |
| `%x` | `%ndc` |
| `%X` | `%properties` |

### [](https://logging.apache.org/log4j/2.x/migrate-from-log4j1.html#ConfigurationCompatibility)Use Log4j 1 to Log4j 2 bridge

If you cannot convert your configuration files from Log4j 1 to Log4j 2, the Log4j 1 to Log4j 2 bridge can convert your configuration files at runtime. To use this feature, you need to [Install the Log4j 1 to Log4j 2 bridge](https://logging.apache.org/log4j/2.x/migrate-from-log4j1.html#log4j-1-2-api-installation) and set one of the following configuration properties:

#### [](https://logging.apache.org/log4j/2.x/migrate-from-log4j1.html#log4j1.compatibility)`log4j1.compatibility`

| Env. variable | LOG4J_COMPATIBILITY |
| --- |
| Type | `boolean` |
| Default value | `false` |

If set to `true`, Log4j 2 will:

*   Scan the classpath to find Log4j 1 configuration files in the following standard locations:

    *   `log4j-test.properties`,

    *   `log4j-test.xml`,

    *   `log4j.properties`,

    *   `log4j.xml`.

*   (since `2.24.0`) Enable the usage of the `o.a.log4j.PropertyConfigurator` and `o.a.log4j.xml.DOMConfigurator` classes in your code.

#### [](https://logging.apache.org/log4j/2.x/migrate-from-log4j1.html#log4j.configuration)`log4j.configuration`

| Env. variable | LOG4J_CONFIGURATION_FILE |
| --- |
| Type | [Path](https://docs.oracle.com/javase/8/docs/api/java/nio/file/Path.html) or [URI](https://docs.oracle.com/javase/8/docs/api/java/net/URI.html) |
| Default value | `null` |

If not `null`, Log4j 2 will try to retrieve a **Log4j 1** configuration file from the given location. The configuration file name must end in `.properties` (Log4j 1 properties format) or `.xml` (Log4j 1 XML format). See also [limitations of Log4j 1 configuration compatibility layer](https://logging.apache.org/log4j/2.x/migrate-from-log4j1.html##limitations-of-the-log4j-1-x-bridge).

#### [](https://logging.apache.org/log4j/2.x/migrate-from-log4j1.html#limitations-of-the-log4j-1-x-bridge)[](https://logging.apache.org/log4j/2.x/migrate-from-log4j1.html)Limitations of runtime configuration conversion

The support for Log4j 1 configuration files uses Log4j 2 Core plugin system and can be extended by implementing a plugin of type `org.apache.log4j.builders.Builder`.

Appenders

*   [`org.apache.log4j.AsyncAppender`](https://logging.apache.org/log4j/2.x/plugin-reference.html#org-apache-logging-log4j_log4j-1-2-api_org-apache-log4j-builders-appender-AsyncAppenderBuilder),

*   [`org.apache.log4j.ConsoleAppender`](https://logging.apache.org/log4j/2.x/plugin-reference.html#org-apache-logging-log4j_log4j-1-2-api_org-apache-log4j-builders-appender-ConsoleAppenderBuilder),

*   [`org.apache.log4j.DailyRollingFileAppender`](https://logging.apache.org/log4j/2.x/plugin-reference.html#org-apache-logging-log4j_log4j-1-2-api_org-apache-log4j-builders-appender-DailyRollingFileAppenderBuilder),

*   [`org.apache.log4j.FileAppender`](https://logging.apache.org/log4j/2.x/plugin-reference.html#org-apache-logging-log4j_log4j-1-2-api_org-apache-log4j-builders-appender-FileAppenderBuilder),

*   [`org.apache.log4j.RollingFileAppender`](https://logging.apache.org/log4j/2.x/plugin-reference.html#org-apache-logging-log4j_log4j-1-2-api_org-apache-log4j-builders-appender-RollingFileAppenderBuilder),

*   [`org.apache.log4j.net.SocketAppender`](https://logging.apache.org/log4j/2.x/plugin-reference.html#org-apache-logging-log4j_log4j-1-2-api_org-apache-log4j-builders-appender-SocketAppenderBuilder),

*   [`org.apache.log4j.net.SyslogAppender`](https://logging.apache.org/log4j/2.x/plugin-reference.html#org-apache-logging-log4j_log4j-1-2-api_org-apache-log4j-builders-appender-SyslogAppenderBuilder),

*   [`org.apache.log4j.rewrite.RewriteAppender`](https://logging.apache.org/log4j/2.x/plugin-reference.html#org-apache-logging-log4j_log4j-1-2-api_org-apache-log4j-builders-appender-RewriteAppenderBuilder),

*   [`org.apache.log4j.rolling.RollingFileAppender`](https://logging.apache.org/log4j/2.x/plugin-reference.html#org-apache-logging-log4j_log4j-1-2-api_org-apache-log4j-builders-appender-EnhancedRollingFileAppenderBuilder),

*   [`org.apache.log4j.varia.NullAppender`](https://logging.apache.org/log4j/2.x/plugin-reference.html#org-apache-logging-log4j_log4j-1-2-api_org-apache-log4j-builders-appender-NullAppenderBuilder).

Filters

*   [`org.apache.log4j.varia.DenyAllFilter`](https://logging.apache.org/log4j/2.x/plugin-reference.html#org-apache-logging-log4j_log4j-1-2-api_org-apache-log4j-builders-filter-DenyAllFilterBuilder),

*   [`org.apache.log4j.varia.LevelMatchFilter`](https://logging.apache.org/log4j/2.x/plugin-reference.html#org-apache-logging-log4j_log4j-1-2-api_org-apache-log4j-builders-filter-LevelMatchFilterBuilder),

*   [`org.apache.log4j.varia.LevelRangeFilter`](https://logging.apache.org/log4j/2.x/plugin-reference.html#org-apache-logging-log4j_log4j-1-2-api_org-apache-log4j-builders-filter-LevelRangeFilterBuilder),

*   [`org.apache.log4j.varia.StringMatchFilter`](https://logging.apache.org/log4j/2.x/plugin-reference.html#org-apache-logging-log4j_log4j-1-2-api_org-apache-log4j-builders-filter-StringMatchFilterBuilder).

Layouts

*   [`org.apache.log4j.HTMLLayout`](https://logging.apache.org/log4j/2.x/plugin-reference.html#org-apache-logging-log4j_log4j-1-2-api_org-apache-log4j-builders-layout-HtmlLayoutBuilder),

*   [`org.apache.log4j.PatternLayout`](https://logging.apache.org/log4j/2.x/plugin-reference.html#org-apache-logging-log4j_log4j-1-2-api_org-apache-log4j-builders-layout-PatternLayoutBuilder) and `org.apache.log4j.EnhancedPatternLayout`,

*   [`org.apache.log4j.SimpleLayout`](https://logging.apache.org/log4j/2.x/plugin-reference.html#org-apache-logging-log4j_log4j-1-2-api_org-apache-log4j-builders-layout-SimpleLayoutBuilder),

*   [`org.apache.log4j.TTCCLayout`](https://logging.apache.org/log4j/2.x/plugin-reference.html#org-apache-logging-log4j_log4j-1-2-api_org-apache-log4j-builders-layout-TTCCLayoutBuilder),

*   [`org.apache.log4j.xml.XMLLayout`](https://logging.apache.org/log4j/2.x/plugin-reference.html#org-apache-logging-log4j_log4j-1-2-api_org-apache-log4j-builders-layout-XmlLayoutBuilder).

Triggering policies

*   [`org.apache.log4j.rolling.CompositeTriggeringPolicy`](https://logging.apache.org/log4j/2.x/plugin-reference.html#org-apache-logging-log4j_log4j-1-2-api_org-apache-log4j-builders-rolling-CompositeTriggeringPolicyBuilder),

*   [`org.apache.log4j.rolling.SizeBasedTriggeringPolicy`](https://logging.apache.org/log4j/2.x/plugin-reference.html#org-apache-logging-log4j_log4j-1-2-api_org-apache-log4j-builders-rolling-SizeBasedTriggeringPolicyBuilder),

*   [`org.apache.log4j.rolling.TimeBasedRollingPolicy`](https://logging.apache.org/log4j/2.x/plugin-reference.html#org-apache-logging-log4j_log4j-1-2-api_org-apache-log4j-builders-rolling-TimeBasedRollingPolicyBuilder).

## [](https://logging.apache.org/log4j/2.x/migrate-from-log4j1.html#option-1-use-the-log4j-1-x-bridge-log4j-1-2-api)[](https://logging.apache.org/log4j/2.x/migrate-from-log4j1.html)Log4j 1 to Log4j 2 bridge

To help users with the migration process, a Log4j 1 to Log4j 2 bridge is available. The bridge can fulfill four separate functions:

*   It forwards all [Log4j 1 API](https://logging.apache.org/log4j/2.x/migrate-from-log4j1.html#log4j-1-api-methods) method calls to the Log4j 2 API. See [how to use the bridge for Log4j 1 API migration](https://logging.apache.org/log4j/2.x/migrate-from-log4j1.html#api-use-bridge) for more details.

*   Since version 2.17.2 the bridge supports the usage of some components written for Log4j 1 inside Log4j 2 Core. See [how to use the bridge for Log4j 1 Backend migration](https://logging.apache.org/log4j/2.x/migrate-from-log4j1.html#migrate-custom-components) for more details.

*   It provides limited support for programmatic configuration of Log4j 2 Core, using Log4j 1 method calls. This functionality requires the [`log4j1.compatibility` configuration property](https://logging.apache.org/log4j/2.x/migrate-from-log4j1.html#log4j1.compatibility) to be set to `true`.

*   It provides a limited support for Log4j 1 configuration file formats. See [how to use the bridge for Log4j 1 Configuration file migration](https://logging.apache.org/log4j/2.x/migrate-from-log4j1.html#ConfigurationCompatibility) for more details.

### [](https://logging.apache.org/log4j/2.x/migrate-from-log4j1.html#log4j-1-2-api-installation)Installation

Since the Log4j 1 to Log4j 2 Bridge **replaces** Log4j 1 classes, it is incompatible with the following artifacts:

*   [`log4j:log4j`](https://central.sonatype.com/artifact/log4j/log4j)

*   [`ch.qos.reload4j:reload4j`](https://central.sonatype.com/artifact/ch.qos.reload4j/reload4j),

*   [`org.slf4j:log4j-over-slf4j`](https://central.sonatype.com/artifact/org.slf4j/log4j-over-slf4j)

Before installing the bridge, you need to make sure that none of the artifacts above are present in your runtime classpath.

To install the bridge, add the following dependency to your application:

*   Maven

*   Gradle

We assume you use [`log4j-bom`](https://logging.apache.org/log4j/2.x/components.html#log4j-bom) for dependency management.

```
<dependency>
  <groupId>org.apache.logging.log4j</groupId>
  <artifactId>log4j-1.2-api</artifactId>
  <scope>runtime</scope>
</dependency>
```

xml

### [](https://logging.apache.org/log4j/2.x/migrate-from-log4j1.html#when-to-stop-using-the-log4j-1-x-bridge)When to stop using the Log4j 1 to Log4j 2 bridge

The Log4j 1 to Log4j 2 bridge is not conceived as a long term solution. Once:

*   you have migrated your logging code to use Log4j 2 API (see [Migrate code from Log4j 1 API to Log4j 2 API](https://logging.apache.org/log4j/2.x/migrate-from-log4j1.html#api-code-migration)),

*   you have migrated your configuration files to use the Log4j 2 configuration format (see [Log4j 1 Configuration file migration](https://logging.apache.org/log4j/2.x/migrate-from-log4j1.html#configuration-file-migration)),

*   upgraded all the dependencies that use Log4j 1 directly to newer versions that use a proper logging API (JCL, Log4j 2 API, JBoss logging, SLF4J),

the bridge is no longer necessary and should be removed.

The separation of logging APIs from logging implementations started in 2002, with the release of [Apache Commons Logging](https://commons.apache.org/proper/commons-logging/) (formerly known as Jakarta Commons Logging).

We are unaware of any **maintained** library that is currently using Log4j 1. However, if this is your case, please contact the library maintainer and ask them to migrate to one of the available logging APIs.
