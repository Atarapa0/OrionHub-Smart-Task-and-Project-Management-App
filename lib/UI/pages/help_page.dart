import 'package:flutter/material.dart';
import 'package:todo_list/UI/widget/custom_app_bar.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.green.shade600, Colors.teal.shade600],
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.help, color: Colors.white, size: 28),
                    SizedBox(width: 12),
                    Text(
                      'Yardım & Kullanım Kılavuzu',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'OrionHub uygulamasını nasıl kullanacağınızı öğrenin',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ),

          // Tab Bar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.green.shade600,
              unselectedLabelColor: Colors.grey.shade600,
              indicatorColor: Colors.green.shade600,
              isScrollable: true,
              tabs: const [
                Tab(text: 'Başlangıç', icon: Icon(Icons.play_arrow)),
                Tab(text: 'Görevler', icon: Icon(Icons.task)),
                Tab(text: 'Projeler', icon: Icon(Icons.folder)),
                Tab(text: 'SSS', icon: Icon(Icons.quiz)),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGettingStartedTab(),
                _buildTasksTab(),
                _buildProjectsTab(),
                _buildFAQTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGettingStartedTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionCard(
            title: 'OrionHub\'e Hoş Geldiniz! 🎉',
            icon: Icons.celebration,
            color: Colors.purple,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'OrionHub, kişisel görevlerinizi ve takım projelerinizi yönetmenize yardımcı olan kapsamlı bir görev yönetim uygulamasıdır.',
                  style: TextStyle(fontSize: 16, height: 1.5),
                ),
                const SizedBox(height: 16),
                _buildFeatureItem(
                  Icons.task_alt,
                  'Kişisel Görevler',
                  'Günlük görevlerinizi oluşturun, düzenleyin ve takip edin',
                ),
                _buildFeatureItem(
                  Icons.group_work,
                  'Takım Projeleri',
                  'Ekip üyeleriyle birlikte projeler oluşturun ve yönetin',
                ),
                _buildFeatureItem(
                  Icons.schedule,
                  'Zaman Yönetimi',
                  'Görevlerinize tarih ve saat ekleyerek zamanınızı planlayın',
                ),
                _buildFeatureItem(
                  Icons.notifications,
                  'Akıllı Bildirimler',
                  'Görev hatırlatmaları ve proje davetleri alın',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'İlk Adımlar',
            icon: Icons.rocket_launch,
            color: Colors.orange,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStepItem(
                  '1',
                  'Profil Bilgilerinizi Kontrol Edin',
                  'Profil sayfasından bilgilerinizi görüntüleyin ve gerekirse güncelleyin.',
                ),
                _buildStepItem(
                  '2',
                  'İlk Görevinizi Oluşturun',
                  'Ana sayfada "+" butonuna tıklayarak ilk görevinizi ekleyin.',
                ),
                _buildStepItem(
                  '3',
                  'Proje Oluşturun veya Katılın',
                  'Projeler sekmesinden yeni proje oluşturun veya davetleri kabul edin.',
                ),
                _buildStepItem(
                  '4',
                  'Bildirimleri Kontrol Edin',
                  'Bildirimler sayfasından görev hatırlatmalarını, proje davetlerini ve görev atama bildirimlerini takip edin. Bildirimler 4 kategoride organize edilmiştir.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionCard(
            title: 'Görev Yönetimi',
            icon: Icons.task,
            color: Colors.blue,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHelpItem(
                  'Yeni Görev Ekleme',
                  'Ana sayfada sağ alt köşedeki "+" butonuna tıklayın. Görev başlığı, açıklama, öncelik seviyesi, kategori ve bitiş tarihi ekleyebilirsiniz.',
                  Icons.add_circle,
                ),
                _buildHelpItem(
                  'Görev Tamamlama',
                  'Görevin yanındaki daire simgesine tıklayarak görevi tamamlandı olarak işaretleyin.',
                  Icons.check_circle,
                ),
                _buildHelpItem(
                  'Görev Düzenleme',
                  'Görevin üzerine uzun basarak düzenleme seçeneklerine erişebilirsiniz.',
                  Icons.edit,
                ),
                _buildHelpItem(
                  'Görev Silme',
                  'Görevin yanındaki menü butonundan "Sil" seçeneğini kullanın.',
                  Icons.delete,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Öncelik Seviyeleri',
            icon: Icons.priority_high,
            color: Colors.red,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPriorityItem(
                  'ACİL',
                  Colors.red,
                  'Hemen yapılması gereken görevler',
                ),
                _buildPriorityItem(
                  'YÜKSEK',
                  Colors.orange,
                  'Önemli ve acil görevler',
                ),
                _buildPriorityItem(
                  'ORTA',
                  Colors.yellow.shade700,
                  'Normal öncelikli görevler',
                ),
                _buildPriorityItem(
                  'DÜŞÜK',
                  Colors.green,
                  'Ertelenebilir görevler',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Filtreleme ve Arama',
            icon: Icons.filter_list,
            color: Colors.purple,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHelpItem(
                  'Öncelik Filtresi',
                  'Görevleri öncelik seviyesine göre filtreleyerek odaklanmak istediğiniz görevleri görün.',
                  Icons.filter_1,
                ),
                _buildHelpItem(
                  'Durum Filtresi',
                  'Bekleyen, devam eden veya tamamlanan görevleri ayrı ayrı görüntüleyin.',
                  Icons.filter_2,
                ),
                _buildHelpItem(
                  'Tarih Filtresi',
                  'Bugünkü görevler, geciken görevler veya yaklaşan görevleri filtreleyin.',
                  Icons.filter_3,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionCard(
            title: 'Proje Yönetimi',
            icon: Icons.folder,
            color: Colors.indigo,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHelpItem(
                  'Yeni Proje Oluşturma',
                  'Projeler sekmesinde "Yeni Proje Oluştur" butonuna tıklayın. Proje adı ve açıklama ekleyin.',
                  Icons.create_new_folder,
                ),
                _buildHelpItem(
                  'Üye Ekleme',
                  'Proje detay sayfasında "Üye Ekle" butonunu kullanarak email ile kullanıcı arayın ve projeye davet edin.',
                  Icons.person_add,
                ),
                _buildHelpItem(
                  'Görev Atama',
                  'Proje görevlerini oluşturduktan sonra proje üyelerine atayabilirsiniz.',
                  Icons.assignment_ind,
                ),
                _buildHelpItem(
                  'Proje İstatistikleri',
                  'Proje detay sayfasında "İstatistikler" sekmesinden proje ilerlemesini takip edin.',
                  Icons.analytics,
                ),
                _buildHelpItem(
                  'Proje Silme',
                  'Sadece proje sahibi projeyi silebilir. Proje detay sayfasında sağ üst menüden "Projeyi Sil" seçeneğini kullanın. Bu işlem geri alınamaz ve tüm proje verileri silinir.',
                  Icons.delete_forever,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Roller ve İzinler',
            icon: Icons.admin_panel_settings,
            color: Colors.teal,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRoleItem(
                  'SAHİP',
                  Colors.purple,
                  'Projeyi oluşturan kişi. Tüm yetkilere sahiptir.',
                  [
                    'Üye ekleme/çıkarma',
                    'Görev oluşturma/silme',
                    'Rol değiştirme',
                  ],
                ),
                _buildRoleItem(
                  'YÖNETİCİ',
                  Colors.blue,
                  'Proje yönetim yetkilerine sahip üye.',
                  ['Üye ekleme', 'Görev oluşturma', 'Görev atama'],
                ),
                _buildRoleItem('ÜYE', Colors.green, 'Standart proje üyesi.', [
                  'Atanan görevleri görme',
                  'Kendi görevlerini tamamlama',
                ]),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Proje Davetleri',
            icon: Icons.mail,
            color: Colors.orange,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHelpItem(
                  'Davet Gönderme',
                  'Proje sahibi veya yöneticisi, "Üye Ekle" butonunu kullanarak email ile davet gönderebilir.',
                  Icons.send,
                ),
                _buildHelpItem(
                  'Davet Alma',
                  'Davet aldığınızda bildirimler sayfasında görüntülenir. "Kabul Et" veya "Reddet" seçeneklerini kullanın.',
                  Icons.inbox,
                ),
                _buildHelpItem(
                  'Davet Durumu',
                  'Gönderilen davetlerin durumunu (beklemede, kabul edildi, reddedildi) takip edebilirsiniz.',
                  Icons.track_changes,
                ),
                _buildHelpItem(
                  'Davet İptal Etme',
                  'Proje sahibi, bekleyen davetleri proje detay sayfasındaki "Bekleyen Davetler" bölümünden iptal edebilir.',
                  Icons.cancel,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionCard(
            title: 'Sıkça Sorulan Sorular',
            icon: Icons.quiz,
            color: Colors.amber,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFAQItem(
                  'Şifremi nasıl değiştirebilirim?',
                  'Profil sayfasından "Ayarlar" menüsüne girin. "Şifre Değiştir" bölümünde mevcut şifrenizi girin ve yeni şifrenizi belirleyin.',
                ),
                _buildFAQItem(
                  'Görevlerime tarih nasıl eklerim?',
                  'Görev oluştururken veya düzenlerken "Bitiş Tarihi Seç" butonuna tıklayın. İsteğe bağlı olarak saat de ekleyebilirsiniz.',
                ),
                _buildFAQItem(
                  'Bildirimler nasıl çalışır?',
                  'Sistem otomatik olarak görev hatırlatmaları, proje davetleri ve görev atamaları için bildirim gönderir. Bildirimler sayfasında 4 kategori bulunur: Tümü, Proje Bildirimleri, Kişisel Görevler ve Davetler.',
                ),
                _buildFAQItem(
                  'Projeden nasıl ayrılırım?',
                  'Şu anda projeden ayrılma özelliği bulunmamaktadır. Proje sahibi sizi projeden çıkarabilir.',
                ),
                _buildFAQItem(
                  'Gönderdiğim davetleri iptal edebilir miyim?',
                  'Evet, proje sahibi olarak bekleyen davetleri proje detay sayfasından iptal edebilirsiniz. Kabul edilmiş veya reddedilmiş davetler iptal edilemez.',
                ),
                _buildFAQItem(
                  'Verilerim güvende mi?',
                  'Evet, tüm verileriniz güvenli Supabase sunucularında şifrelenerek saklanmaktadır.',
                ),
                _buildFAQItem(
                  'Uygulama ücretsiz mi?',
                  'Evet, OrionHub tamamen ücretsiz bir uygulamadır.',
                ),
                _buildFAQItem(
                  'Teknik destek nasıl alabilirim?',
                  'Herhangi bir sorun yaşadığınızda uygulama geliştiricisi ile iletişime geçebilirsiniz.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'İpuçları',
            icon: Icons.lightbulb,
            color: Colors.yellow.shade700,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTipItem(
                  '💡',
                  'Görevlerinizi kategorilere ayırarak daha organize olun.',
                ),
                _buildTipItem(
                  '⏰',
                  'Önemli görevlere mutlaka tarih ve saat ekleyin.',
                ),
                _buildTipItem(
                  '🎯',
                  'Öncelik seviyelerini doğru kullanarak odaklanın.',
                ),
                _buildTipItem(
                  '👥',
                  'Takım projelerinde düzenli iletişim kurun.',
                ),
                _buildTipItem(
                  '📊',
                  'Proje istatistiklerini takip ederek ilerlemenizi ölçün.',
                ),
                _buildTipItem(
                  '🔔',
                  'Bildirimler sayfasını düzenli kontrol ederek önemli güncellemeleri kaçırmayın.',
                ),
                _buildTipItem(
                  '🗑️',
                  'Artık ihtiyaç duymadığınız projeleri güvenle silebilirsiniz (sadece proje sahibi).',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget content,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.purple, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(String step, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                step,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String title, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityItem(String priority, Color color, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              priority,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(description, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleItem(
    String role,
    Color color,
    String description,
    List<String> permissions,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  role,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...permissions.map(
            (permission) => Padding(
              padding: const EdgeInsets.only(left: 16, top: 4),
              child: Row(
                children: [
                  Icon(Icons.check, color: color, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    permission,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            answer,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildTipItem(String emoji, String tip) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(tip, style: const TextStyle(fontSize: 14, height: 1.4)),
          ),
        ],
      ),
    );
  }
}
