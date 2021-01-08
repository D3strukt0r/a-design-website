<?php
/**
 * General Configuration
 *
 * All of your system's general configuration settings go in here. You can see a
 * list of the available settings in vendor/craftcms/cms/src/config/GeneralConfig.php.
 *
 * @see \craft\config\GeneralConfig
 */

use craft\helpers\App;

return [
    // Craft config settings from .env variables
    'aliases' => [
        '@assetsUrl' => App::env('ASSETS_URL'),
        '@web' => App::env('SITE_URL'),
        '@webroot' => App::env('WEB_ROOT_PATH'),
    ],
    'allowUpdates' => (bool) App::env('ALLOW_UPDATES'),
    'allowAdminChanges' => (bool) App::env('ALLOW_ADMIN_CHANGES'), // Set this to `false` to prevent administrative changes from being made
    'backupOnUpdate' => (bool) App::env('BACKUP_ON_UPDATE'),
    'devMode' => (bool) App::env('DEV_MODE'), // Dev Mode (see https://craftcms.com/guides/what-dev-mode-does)
    'enableTemplateCaching' => (bool) App::env('ENABLE_TEMPLATE_CACHING'),
    'isSystemLive' => (bool) App::env('IS_SYSTEM_LIVE'),
    'resourceBasePath' => App::env('WEB_ROOT_PATH').'/cpresources',
    'runQueueAutomatically' => (bool) App::env('RUN_QUEUE_AUTOMATICALLY'),
    'securityKey' => App::env('SECURITY_KEY'), // The secure key Craft will use for hashing and encrypting data
    'siteUrl' => [
        'default' => '@web',
        'en' => '@web/en',
        'fr' => '@web/fr',
    ],
    // Craft config settings from constants
    'cacheDuration' => false,
    'cpTrigger' => 'admin', // Control panel trigger word
    'defaultSearchTermOptions' => [
        'subLeft' => true,
        'subRight' => true,
    ],
    'defaultTokenDuration' => 'P2W',
    'defaultWeekStartDay' => 1, // Default Week Start Day (0 = Sunday, 1 = Monday...)
    'enableCsrfProtection' => true,
    'errorTemplatePrefix' => 'errors/',
    'generateTransformsBeforePageLoad' => true,
    'maxCachedCloudImageSize' => 3000,
    'maxUploadFileSize' => '100M',
    'omitScriptNameInUrls' => true, // Whether generated URLs should omit "index.php"
    'useEmailAsUsername' => false,
    'usePathInfo' => true,
    'useProjectConfigFile' => true,

    // Global settings
    // '*' => [
    //     // Default Week Start Day (0 = Sunday, 1 = Monday...)
    //     'defaultWeekStartDay' => 1,
    //
    //     // Whether generated URLs should omit "index.php"
    //     'omitScriptNameInUrls' => true,
    //
    //     // Control panel trigger word
    //     'cpTrigger' => 'admin',
    //
    //     // The secure key Craft will use for hashing and encrypting data
    //     'securityKey' => App::env('SECURITY_KEY'),
    //
    //     'siteUrl' => [
    //         'default' => App::env('DEFAULT_SITE_URL'),
    //         'en' => App::env('DEFAULT_SITE_URL').'/en',
    //         'fr' => App::env('DEFAULT_SITE_URL').'/fr',
    //     ],
    // ],

    // Dev environment settings
    // 'dev' => [
    //     // Dev Mode (see https://craftcms.com/guides/what-dev-mode-does)
    //     'devMode' => true,
    // ],

    // Staging environment settings
    // 'staging' => [
    //     // Set this to `false` to prevent administrative changes from being made on staging
    //     'allowAdminChanges' => false,
    // ],

    // Production environment settings
    // 'production' => [
    //     // Set this to `false` to prevent administrative changes from being made on production
    //     'allowAdminChanges' => false,
    // ],
];
