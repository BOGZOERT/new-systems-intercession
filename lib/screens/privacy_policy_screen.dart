import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  final bool showAcceptButton;

  const PrivacyPolicyScreen({super.key, this.showAcceptButton = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Пользовательское соглашение'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ПОЛЬЗОВАТЕЛЬСКОЕ СОГЛАШЕНИЕ',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'об обработке персональных данных',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            const Text(
              '1. ОБЩИЕ ПОЛОЖЕНИЯ',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '1.1. Настоящее Пользовательское соглашение (далее — Соглашение) разработано в соответствии '
                  'с требованиями Федерального закона от 27.07.2006 № 152-ФЗ «О персональных данных» и '
                  'определяет порядок обработки персональных данных и меры по обеспечению безопасности '
                  'персональных данных, предпринимаемые приложением «Таблица смен» (далее — Приложение).\n\n'
                  '1.2. Используя Приложение, Пользователь выражает своё безусловное согласие с настоящим '
                  'Соглашением и условиями обработки его персональных данных. В случае несогласия с условиями '
                  'Соглашения Пользователь должен прекратить использование Приложения.\n\n'
                  '1.3. Приложение обрабатывает персональные данные Пользователя в следующих целях:\n'
                  '• Идентификация Пользователя в Приложении;\n'
                  '• Предоставление Пользователю доступа к функциям Приложения;\n'
                  '• Учёт рабочего времени и графика смен;\n'
                  '• Организация замен и коммуникации между сотрудниками.',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 16),
            const Text(
              '2. СОСТАВ ОБРАБАТЫВАЕМЫХ ДАННЫХ',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '2.1. Приложение обрабатывает следующие персональные данные Пользователя:\n'
                  '• Фамилия, имя, отчество;\n'
                  '• Адрес электронной почты (email);\n'
                  '• Номер телефона (при указании);\n'
                  '• Фотография (при загрузке);\n'
                  '• Данные о категории и графике работы;\n'
                  '• Сведения о заступлении на смены и заменах.\n\n'
                  '2.2. Приложение не обрабатывает специальные категории персональных данных, '
                  'касающихся расовой, национальной принадлежности, политических взглядов, '
                  'религиозных или философских убеждений, состояния здоровья, интимной жизни.',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 16),
            const Text(
              '3. ПРАВА И ОБЯЗАННОСТИ СТОРОН',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '3.1. Пользователь имеет право:\n'
                  '• На получение информации, касающейся обработки его персональных данных;\n'
                  '• На уточнение, блокирование или уничтожение его персональных данных;\n'
                  '• На отзыв согласия на обработку персональных данных;\n'
                  '• На обжалование неправомерных действий Приложения.\n\n'
                  '3.2. Приложение обязуется:\n'
                  '• Использовать полученные данные исключительно для целей, указанных в п. 1.3;\n'
                  '• Не разглашать персональные данные Пользователя третьим лицам;\n'
                  '• Обеспечить конфиденциальность и безопасность обрабатываемых данных;\n'
                  '• Блокировать или удалить персональные данные по запросу Пользователя.',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 16),
            const Text(
              '4. ХРАНЕНИЕ И ЗАЩИТА ДАННЫХ',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '4.1. Персональные данные Пользователя хранятся на серверах Firebase (Google Cloud), '
                  'соответствующих требованиям безопасности ISO 27001, SOC 1, SOC 2, SOC 3.\n\n'
                  '4.2. Приложение принимает необходимые организационные и технические меры для защиты '
                  'персональных данных Пользователя от неправомерного или случайного доступа, уничтожения, '
                  'изменения, блокирования, копирования, распространения.\n\n'
                  '4.3. Срок хранения персональных данных: до момента отзыва согласия Пользователем '
                  'или прекращения деятельности Приложения.',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 16),
            const Text(
              '5. ЗАКЛЮЧИТЕЛЬНЫЕ ПОЛОЖЕНИЯ',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '5.1. Настоящее Соглашение вступает в силу с момента начала использования Приложения '
                  'и действует бессрочно.\n\n'
                  '5.2. Приложение оставляет за собой право вносить изменения в настоящее Соглашение. '
                  'Новая редакция Соглашения вступает в силу с момента её опубликования в Приложении.\n\n'
                  '5.3. По всем вопросам, связанным с обработкой персональных данных, Пользователь может '
                  'связаться с администратором Приложения по электронной почте.',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 32),

            if (showAcceptButton)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    context.read<AuthProvider>().acceptPrivacyPolicy();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Принимаю', style: TextStyle(fontSize: 16)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}