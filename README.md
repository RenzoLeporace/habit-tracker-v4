# Mi espacio

Aplicación Flutter de hábitos y finanzas personales.

**[Abrir demo en GitHub Pages](https://renzoleporace.github.io/habit-tracker-v4/)**

## Acceso de demostración

Usuario: `demo` · Contraseña: `demo123`.

El acceso está implementado mediante `AuthRepository`. Para migrarlo a una base de datos o servicio de identidad, reemplazá `DemoAuthRepository` en `lib/main.dart`. Este acceso local no ofrece seguridad para datos sensibles.

## Finanzas

El tablero sigue `presupuesto_2026 (2) (2).xlsx`: el ingreso mensual suma todos los ingresos; los gastos operativos incluyen solo Servicios, Supermercado y Gastos personales; Facturas, Ahorros y Débito se descuentan por separado. El restante es ingreso menos esas cuatro salidas. Los importes planeados y el ahorro acumulado se cargan manualmente. Otras categorías, como Farmacia, aparecen en el registro pero no afectan el restante, igual que en las fórmulas del Excel.

Los movimientos guardan fecha, descripción, categoría, tipo e importe. Las categorías adicionales pueden crearse desde la pantalla de finanzas. Los datos se guardan localmente con `shared_preferences` por instalación. `FinanceRepository` permite sustituir este adaptador por una implementación con base de datos sin cambiar la interfaz ni los cálculos.

Los hábitos también se guardan localmente. Su origen actual conserva los hábitos de muestra en una instalación nueva.

## Rutina y tareas

«Mi día a día» permite registrar actividades con fecha, horario y categoría, recorrer los días y verlas en una línea de tiempo. El análisis de rutina es local: identifica bloques que se repiten en días distintos con inicios separados por hasta 30 minutos, y muestra huecos de al menos 30 minutos del día seleccionado. No usa un servicio de IA externo.

«Tareas semanales» muestra semanas de lunes a domingo. Podés crear y completar tareas, borrarlas o moverlas a otro día de la semana; al moverlas vuelven a quedar pendientes. Ambas secciones usan `RoutineRepository` y guardado local con `shared_preferences`, preparadas para un adaptador de base de datos.

## Ejecutar

```sh
flutter pub get
flutter run
flutter test
```

En Windows, los plugins Flutter requieren habilitar el modo de desarrollador para la creación de enlaces simbólicos.
