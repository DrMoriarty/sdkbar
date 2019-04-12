# TROUBLESHOOTING

## Проблемы сборки

Иногда после обновления некоторых плагинов или библиотек игра перестанет собираться с такими ошибками:

* What went wrong:
Execution failed for task ':gems:transformClassesWithMultidexlistForDebug'.
> com.android.build.api.transform.TransformException: Error while generating the main dex list.

Это значит, что в момент финальной линковки приложения произошло страшное. Для получения конкретики переходим в каталог frameworks/runtime-src/proj.android и выполняем команду:

./gradlew assembleDebug --stacktrace

Теперь в случае проблемы нам вывалится полный стек сборщика. Вверху будут видны обобщённые эксепшены "за всё хорошее, против всего плохого", а ниже по стеку уже можно разглядеть причину этого буйного веселья. Например, можно увидеть такое сообщение:

Program type already present: android.support.v4.app.LoaderManager$LoaderCallbacks

что означает двукратное вхождение типа в собираемый пакет.

Ниже рассмотрим варианты действий при типовых ошибках:

### Не хватило оперативной памяти для сбора всех библиотек в один файл. 
В этом случае проверяем файл frameworks/runtime-src/proj.android/gradle.properties на наличие флага org.gradle.jvmargs=-XX:MaxPermSize=2048m
Если флаг есть, а gradle продолжает сообщать "out of memory", то увеличиваем значение и пробуем ещё раз.

### Не найдена какая либо нужная библиотека.
Это обычно происходит, если версия SDK не совпадает с версией сборочных инструментов и/или с версией библиотек поддержки.
В этом случае сразу смотрим на параметры PROP_COMPILE_SDK_VERSION и PROP_TARGET_SDK_VERSION в файле frameworks/runtime-src/proj.android/gradle.properties (в нашем случае 28), потом смотрим на параметр buildToolsVersion в файле frameworks/runtime-src/proj.android/app/build.gradle (в нашем случае 28.0.3), и потом смотрим на наличие в зависимостях этих библиотек:
compile 'com.android.support:support-v4:28.+'
compile 'com.android.support:appcompat-v7:28.+'
compile 'com.android.support:design:28.+'

Если мажорные версии не совпадают, то значит есть хороший повод их поменять.

### Какой либо класс встречается два раза

Если в стеке видим сообщения вида "Program type already present", значит это наш случай. Во первых, по имени класса определяем виноватый пакет. Во вторых, нужно определить причину двойной линковки данного класса.

Самый простой случай, если в каталогах frameworks/cocos2d-x/cocos/platform/android/libcocos2dx/libs или frameworks/cocos2d-x/cocos/platform/android/java/libs есть jar файлы подозрительно похожие на проблемную библиотеку. Это бывает, если sdkbox плагины (или их остатки) используют более старую версию библиотеки, вытягиваемой по другим зависимостям. В этом случае просто временно убираем подозрительный jar файл в сторону и повторяем сборку. 

Если подозрительных jar файлов не находится, тогда проверяем дерево зависимостей. В каталоге frameworks/runtime-src/proj.android/app выполняем команду:

../gradlew dependencies

В результате мы получим огромную простыню зависимостей, в которой нужно попытаться отыскать проблему. Во первых обращаем внимание на переопределение версий библиотек, выглядит это так:

com.android.support:support-annotations:26.1.0 -> 28.0.0

Тут видно, что требовалась библиотека версии 26.1.0, но сборщик решил, что вместо неё использовать 28.0.0. В большинстве случаев сборщик угадывает наиболее удовлетворительную версию библиотеки, но косяки происходят, если какой либо функционал разбит на более чем одну библиотеку, которые могут фигурировать в разных версиях по разным зависимостям.

Например, такая сладкая парочка:

com.google.android.gms:play-services-basement:16.2.0 (*)
com.google.android.gms:play-services-measurement-base:[16.4.0] -> 16.4.0

может в один прекрасный момент рвануть вышеуказанным эксепшеном. 
Если подозрительная библиотека в разных местах дерева зависимостей фигурирует с разными версиями (особенно мажорными версиями), значит это нужно исправлять. Если эта библиотека сама явно прописана в наших зависимостях в build.gradle, считайте, что нам повезло. Просто меняем версию и voila. Если библиотека является зависимостью второго порядка (её реквестор явно прописан в build.gradle), тогда пытаемся обновить версию реквестора. Иногда бывает так, что реквестора обновить не представляется возможным (обновление приносит кучу других багов, либо обновления по просту нет). Тогда используем чёрную магию с принудительным переопределением версий библиотек.

Первый вариант страшного заклинания выглядит так:

configurations.all {
	resolutionStrategy {
		force 'com.google.firebase:firebase-analytics-impl:16.0.0'
	}
} 

В этом случае явно задаётся полное название библиотеки и требуемая версия.
Если библиотек несколько, но, например, все они находятся в одной группе (имя до :), тогда можно использовать более сильное колдунство:

configurations.all {
	resolutionStrategy {
		eachDependency {
			DependencyResolveDetails details ->
				if (details.requested.group == 'com.google.android.exoplayer') {
					println 'Updating version for: $details.requested.group:$details.requested.name:$details.requested.version --> 2.8.1'
					details.useVersion '2.8.1'
				}
		}
	}
}

Заклинания нужно прописывать в конце build.gradle. При этом, более сильный вариант магии не рекомендуется использовать ночью в полнолуние на кладбище.


## Проблемы runtime

### Креш при первом запуске

При первом старте игра получает информацию о том, из какого источника она была установлена. В этот момент могут происходить такие креши:

java.lang.ClassNotFoundException: Didn't find class "com.google.android.gms.analytics.CampaignTrackingReceiver"

java.lang.NoClassDefFoundError: Failed resolution of: Lcom/android/installreferrer/api/InstallReferrerStateListener

В последнем случае нужно смотреть, есть ли библиотека com.android.installreferrer:installreferrer:1.0 в зависимостях.

В первом случае можно попробовать обновить google services, причём не только compile 'com.google.android.gms:play-services-BLABLABLA:X.Y.Z' но и classpath 'com.google.gms:google-services:4.0.+'

Ещё можно попробовать обновить com.google.android.gms:play-services-analytics.

### Креши от несовместимости версий библиотек

Если в логах приложения творятся ужасы, типа такого:

java.lang.NoSuchFieldError: No static field zzaqu of type [Ljava/lang/String; in class Lcom/google/android/gms/measurement/AppMeasurement$UserProperty

это значит, что две связанные библиотеки рассинхронизировались в версиях. Обычно в стеке видно какая библиотека делала вызов, а в обращении к классу видно какую библиотеку в этот момент вызывали. Дальнейший алгоритм действий подобен тому, что мы проходили в ошибках времени сборки по теме двойное вхождение класса.

Если проблема локализуется в google services или в firebase, тогда дополнительно тут ещё можно воспользоваться методом обновления всего до последнего. Для этого смотрим тут:

https://firebase.google.com/docs/android/setup?authuser=0#available-libraries

и тут:

https://developers.google.com/android/guides/releases

и прописываем всем библиотекам последние релизнутые версии. Данный метод сильный, но вместе с тем и опасный. Неосторожный приключенец может в результате добавить себе больше новых проблем, чем решить старых.

