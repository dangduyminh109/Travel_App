package com.vn.huit.travelApp.config;

import com.vn.huit.travelApp.entity.Category;
import com.vn.huit.travelApp.entity.Destination;
import com.vn.huit.travelApp.entity.Review;
import com.vn.huit.travelApp.entity.User;
import com.vn.huit.travelApp.repository.CategoryRepository;
import com.vn.huit.travelApp.repository.DestinationRepository;
import com.vn.huit.travelApp.repository.ReviewRepository;
import com.vn.huit.travelApp.repository.UserRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@Configuration
public class DataSeeder {
    private static final String CITY_HCMC = "TP.HCM";
    private static final String CITY_VUNG_TAU = "Vũng Tàu";

    private static final String CATEGORY_FOOD = "Ăn uống";
    private static final String CATEGORY_ENTERTAINMENT = "Vui chơi";
    private static final String CATEGORY_HOTEL = "Nghỉ ngơi";
    private static final String CATEGORY_CAFE = "Cafe/check-in";
    private static final String CATEGORY_CULTURE_HISTORY = "Văn hóa/lịch sử";
    private static final String CATEGORY_SHOPPING = "Mua sắm";

    private static final String TYPE_FOOD = "FOOD";
    private static final String TYPE_ENTERTAINMENT = "ENTERTAINMENT";
    private static final String TYPE_HOTEL = "HOTEL";
    private static final String TYPE_CAFE = "CAFE";
    private static final String TYPE_CULTURE_HISTORY = "CULTURE_HISTORY";
    private static final String TYPE_SHOPPING = "SHOPPING";

    private static final String PRICE_FREE = "FREE";
    private static final String PRICE_BUDGET = "BUDGET";
    private static final String PRICE_MODERATE = "MODERATE";
    private static final String PRICE_PREMIUM = "PREMIUM";
    private static final String PRICE_LUXURY = "LUXURY";

    private final CategoryRepository categoryRepository;
    private final DestinationRepository destinationRepository;
    private final ReviewRepository reviewRepository;
    private final UserRepository userRepository;
    private final com.vn.huit.travelApp.service.FirebaseRealtimeService firebaseRealtimeService;

    public DataSeeder(CategoryRepository categoryRepository,
                      DestinationRepository destinationRepository,
                      ReviewRepository reviewRepository,
                      UserRepository userRepository,
                      com.vn.huit.travelApp.service.FirebaseRealtimeService firebaseRealtimeService) {
        this.categoryRepository = categoryRepository;
        this.destinationRepository = destinationRepository;
        this.reviewRepository = reviewRepository;
        this.userRepository = userRepository;
        this.firebaseRealtimeService = firebaseRealtimeService;
    }

    @Bean
    public CommandLineRunner initData() {
        return args -> {
            if (categoryRepository.count() == 0) {
                firebaseRealtimeService.clearAll();
            }
            Map<String, Category> categories = ensureCategories();
            List<Destination> destinations = ensureDestinations(categories);
            ensureUsers();
            ensureReviews(destinations);
        };
    }

    private Map<String, Category> ensureCategories() {
        if (categoryRepository.count() == 0) {
            Category bien = Category.builder().name("Biển").icon("beach_access").build();
            Category nui = Category.builder().name("Núi").icon("terrain").build();
            Category amThuc = Category.builder().name("Ẩm thực").icon("restaurant").build();
            Category thanhPho = Category.builder().name("Thành phố").icon("location_city").build();
            Category vanHoa = Category.builder().name("Văn hóa").icon("museum").build();
            Category lichSu = Category.builder().name("Lịch sử").icon("history_edu").build();
            Category giaiTri = Category.builder().name("Giải trí").icon("local_play").build();
            categoryRepository.saveAll(List.of(bien, nui, amThuc, thanhPho, vanHoa, lichSu, giaiTri));
        }
        List<Category> all = categoryRepository.findAll();
        Map<String, Category> map = new HashMap<>();
        for (Category category : all) {
            map.put(category.getName(), category);
        }
        ensureCategory(map, CATEGORY_FOOD, "restaurant");
        ensureCategory(map, CATEGORY_ENTERTAINMENT, "local_play");
        ensureCategory(map, CATEGORY_HOTEL, "hotel");
        ensureCategory(map, CATEGORY_CAFE, "local_cafe");
        ensureCategory(map, CATEGORY_CULTURE_HISTORY, "museum");
        ensureCategory(map, CATEGORY_SHOPPING, "shopping_bag");
        return map;
    }

    private Category ensureCategory(Map<String, Category> categories, String name, String icon) {
        Category existing = categories.get(name);
        if (existing != null) {
            return existing;
        }

        Category category = categoryRepository.findByName(name)
                .orElseGet(() -> categoryRepository.save(Category.builder()
                        .name(name)
                        .icon(icon)
                        .build()));
        categories.put(category.getName(), category);
        return category;
    }

    private List<Destination> ensureDestinations(Map<String, Category> categories) {
        long existing = destinationRepository.count();
        if (existing == 0) {
            List<Destination> newItems = new ArrayList<>();

            Object[][] placesData = {
                    { "Chợ Bến Thành", "Biểu tượng Sài Gòn",
                            "Ngôi chợ lịch sử này không chỉ là biểu tượng tự hào của người dân Sài Gòn mà còn là trung tâm giao thương sầm uất bậc nhất. Tọa lạc ngay trung tâm thành phố, chợ nổi bật với kiến trúc tháp đồng hồ ở cửa nam đã vắt qua hơn một thế kỷ. Nơi đây quy tụ hàng ngàn sạp hàng đa dạng từ quần áo, vải vóc đến đồ thủ công mỹ nghệ tinh xảo. Đặc biệt, khu ẩm thực bên trong chợ là thiên đường để du khách thưởng thức vô vàn món ngon đặc sắc của Nam Bộ.",
                            "https://upload.wikimedia.org/wikipedia/commons/thumb/9/91/Ben_Thanh_market_2.jpg/960px-Ben_Thanh_market_2.jpg",
                            "Văn hóa", "Sài Gòn,Chợ,Mua sắm", 10.772596, 106.698020, "Miền Nam" },

                    { "Dinh Độc Lập", "Di tích quốc gia đặc biệt",
                            "Công trình này là một di tích quốc gia đặc biệt, mang trong mình những dấu ấn lịch sử hào hùng của dân tộc Việt Nam. Dinh thự gây ấn tượng mạnh bởi quy mô rộng lớn và lối kiến trúc hiện đại xen lẫn triết lý phong thủy phương Đông tinh tế. Du khách có thể bước vào tham quan các căn phòng khánh tiết lộng lẫy, phòng làm việc và cả hệ thống hầm ngầm kiên cố dưới lòng đất. Khuôn viên rợp bóng cây xanh xung quanh cũng tạo nên một không gian vô cùng bình yên giữa lòng Sài Gòn náo nhiệt.",
                            "https://upload.wikimedia.org/wikipedia/commons/d/d0/Dinh_%C4%90%E1%BB%99c_L%E1%BA%ADp_v%C3%A0o_n%C3%A0m_2024.jpg",
                            "Lịch sử", "Lịch sử,Kiến trúc", 10.777093, 106.695393, "Miền Nam" },

                    { "Nhà thờ Đức Bà", "Tuyệt tác kiến trúc cổ",
                            "Nằm ngay trái tim của thành phố, công trình này là một tuyệt tác kiến trúc do người Pháp xây dựng từ cuối thế kỷ 19. Điểm nhấn độc đáo nhất là toàn bộ vật liệu từ xi măng, sắt thép đến những viên gạch đỏ au đều được mang sang từ Pháp. Trải qua bao thăng trầm, sắc đỏ của gạch vẫn giữ nguyên vẻ đẹp vĩnh cửu mà không hề bị rêu phong. Hai tháp chuông vươn cao trên nền trời không chỉ là nơi sinh hoạt tôn giáo mà còn là điểm check-in không thể bỏ lỡ của mọi du khách.",
                            "https://upload.wikimedia.org/wikipedia/commons/thumb/d/d9/Notre_dame_saigon.jpg/960px-Notre_dame_saigon.jpg",
                            "Văn hóa", "Kiến trúc,Sống ảo", 10.779785, 106.699018, "Miền Nam" },

                    { "Bưu điện Trung tâm Sài Gòn", "Kiến trúc Pháp tuyệt mĩ",
                            "Được thiết kế bởi kiến trúc sư lừng danh, đây được xem là một trong những tòa nhà bưu điện đẹp nhất khu vực Đông Nam Á. Bước vào bên trong, bạn sẽ choáng ngợp trước mái vòm cong cổ điển, những bốt điện thoại bằng gỗ và hệ thống bản đồ lịch sử được vẽ tay tỉ mỉ. Kiến trúc mang đậm phong cách Phục Hưng Pháp kết hợp hài hòa với những đường nét trang trí phương Đông. Nơi đây vẫn duy trì các dịch vụ bưu chính truyền thống, mang lại cho du khách cảm giác như đang quay ngược thời gian.",
                            "https://upload.wikimedia.org/wikipedia/commons/thumb/f/fb/Saigon_Central_Post_Office_2022.jpg/960px-Saigon_Central_Post_Office_2022.jpg",
                            "Văn hóa", "Chụp ảnh,Kiến trúc", 10.779836, 106.700030, "Miền Nam" },

                    { "Phố đi bộ Nguyễn Huệ", "Trái tim sôi động",
                            "Kéo dài từ trụ sở UBND Thành phố đến tận bến Bạch Đằng, đây là quảng trường tản bộ hiện đại và đông đúc bậc nhất Sài Gòn. Con phố được lát đá granite sạch sẽ, hai bên là những tòa nhà chọc trời, khách sạn sang trọng và chung cư cà phê độc đáo. Mỗi buổi tối, nơi đây lại trở thành sân khấu lung linh cho các màn biểu diễn nhạc nước, nghệ thuật đường phố và lễ hội rực rỡ. Không khí lúc nào cũng nhộn nhịp, tràn đầy sức trẻ và sự năng động đặc trưng của thành phố mang tên Bác.",
                            "https://upload.wikimedia.org/wikipedia/commons/thumb/d/d1/Ho_Chi_Minh_City%2C_Saigon%2C_Vietnam_%2849579818542%29.jpg/960px-Ho_Chi_Minh_City%2C_Saigon%2C_Vietnam_%2849579818542%29.jpg",
                            "Thành phố", "Giải trí,Đi bộ", 10.773822, 106.703138, "Miền Nam" },

                    { "Landmark 81", "Tòa nhà cao nhất Việt Nam",
                            "Vươn mình kiêu hãnh bên bờ sông Sài Gòn, đây không chỉ là tòa nhà cao nhất Việt Nam mà còn là niềm tự hào của kiến trúc hiện đại. Khu phức hợp này hội tụ đầy đủ các tiện ích đẳng cấp từ trung tâm thương mại sầm uất, rạp chiếu phim đến hệ thống nhà hàng sang trọng. Trải nghiệm tuyệt vời nhất là bước lên đài quan sát Skyview ở những tầng trên cùng để phóng tầm mắt ôm trọn toàn cảnh thành phố lung linh về đêm. Cạnh đó là công viên xanh mát rộng lớn, mang lại không gian thư giãn hoàn hảo cho gia đình và giới trẻ.",
                            "https://upload.wikimedia.org/wikipedia/commons/thumb/4/4e/The_Landmark_81_at_night.jpg/1280px-The_Landmark_81_at_night.jpg",
                            "Thành phố", "Hiện đại,View đẹp", 10.794697, 106.722240, "Miền Nam" },

                    { "Phố cổ Hội An", "Di sản hoài niệm",
                            "Đô thị cổ kính này từng là một thương cảng quốc tế sầm uất, nay thu hút du khách bởi vẻ đẹp hoài niệm, bình yên. Dạo bước qua những con hẻm nhỏ, bạn sẽ bắt gặp những nếp nhà mái ngói phủ rêu phong và bức tường vàng đặc trưng. Khi màn đêm buông xuống, cả khu phố bừng sáng dưới ánh sáng lung linh của hàng ngàn chiếc đèn lồng thủ công tuyệt đẹp. Trải nghiệm ngồi thuyền thả hoa đăng trên sông Hoài và thưởng thức đặc sản cao lầu chắc chắn sẽ để lại những ký ức khó quên.",
                            "https://upload.wikimedia.org/wikipedia/commons/f/f3/PhoCoHoiAn.jpg",
                            "Văn hóa", "Phố cổ,Lồng đèn,Di sản", 15.87944, 108.32825, "Miền Trung" },

                    { "Bảo tàng Chứng tích Chiến tranh", "Kí ức khó phai",
                            "Là điểm đến mang tính giáo dục sâu sắc, bảo tàng lưu giữ và trưng bày hàng chục ngàn hiện vật, hình ảnh chân thực về các cuộc chiến tranh tại Việt Nam. Thông qua các bộ sưu tập tài liệu quý giá, nơi đây tái hiện lại sự khốc liệt của bom đạn và ý chí kiên cường của người dân. Không gian trưng bày ngoài trời còn có nhiều loại máy bay, xe tăng và vũ khí quân sự quy mô lớn. Dù mang nhiều câu chuyện đau thương, bảo tàng luôn lan tỏa thông điệp mạnh mẽ về tình yêu hòa bình đến du khách quốc tế.",
                            "https://upload.wikimedia.org/wikipedia/commons/thumb/3/36/Vietnam-_War_Remnants_Museum.jpg/3840px-Vietnam-_War_Remnants_Museum.jpg",
                            "Lịch sử", "Lịch sử,Trải nghiệm", 10.778103, 106.690182, "Miền Nam" },

                    { "Bến Nhà Rồng", "Nơi Bác Hồ ra đi tìm đường cứu nước",
                            "Nằm êm đềm bên ngã ba sông Sài Gòn, di tích này gắn liền với sự kiện người thanh niên Nguyễn Tất Thành ra đi tìm đường cứu nước. Tòa nhà ban đầu mang kiến trúc phương Tây nhưng lại nổi bật với biểu tượng hai con rồng châu Á uốn lượn trên mái nhà. Ngày nay, nơi đây đã trở thành Bảo tàng Hồ Chí Minh, trưng bày nhiều kỷ vật quý giá về cuộc đời và sự nghiệp của vị lãnh tụ vĩ đại. Tản bộ quanh khuôn viên lộng gió, du khách sẽ cảm nhận được sự giao thoa độc đáo giữa lịch sử hào hùng và sự vươn lên của thành phố.",
                            "https://upload.wikimedia.org/wikipedia/commons/c/c0/Ho_Chi_Minh_Museum%2C_Saigon.jpg",
                            "Lịch sử", "Sông nước,Lịch sử", 10.768131, 106.706788, "Miền Nam" },

                    { "Bãi biển Nha Trang", "Vịnh biển tuyệt đẹp",
                            "Vịnh biển Nha Trang từ lâu đã lọt vào danh sách những vịnh biển đẹp nhất thế giới với sức hút khó cưỡng. Bãi biển uốn cong như một vầng trăng khuyết, ôm trọn lấy làn nước trong xanh ngọc bích và bãi cát trắng mịn trải dài. Khí hậu nơi đây ôn hòa quanh năm, rất lý tưởng cho các hoạt động tắm biển, dù lượn hay lặn ngắm san hô. Bên cạnh cảnh sắc thiên nhiên tuyệt mĩ, hệ thống resort ven biển và nền ẩm thực hải sản phong phú sẽ mang đến một kỳ nghỉ dưỡng trọn vẹn.",
                            "https://upload.wikimedia.org/wikipedia/commons/5/5c/Nha_Trang%2C_Kh%C3%A1nh_H%C3%B2a.png",
                            "Biển", "Biển,Nghỉ mát", 12.238791, 109.196749, "Miền Trung" },

                    { "Phố Tây Bùi Viện", "Khu phố không ngủ",
                            "Mệnh danh là khu phố không ngủ, đây là điểm tụ tập về đêm sôi động nhất dành cho du khách trong và ngoài nước. Khi phố lên đèn, cả đoạn đường cấm xe cộ và nhường chỗ cho những bản nhạc EDM cuồng nhiệt phát ra từ hàng loạt quán bar, pub. Hai bên đường san sát các xe đẩy ẩm thực đường phố, nhà hàng phục vụ đa dạng các món ăn từ Á sang Âu. Không khí tự do, cởi mở và tràn ngập tiếng cười nơi đây chính là thỏi nam châm thu hút những ai yêu thích sự náo nhiệt.",
                            "https://upload.wikimedia.org/wikipedia/commons/thumb/5/52/Bui_Vien_Walking_Street_1.jpg/3840px-Bui_Vien_Walking_Street_1.jpg",
                            "Giải trí", "Ăn nhậu,Nhộn nhịp", 10.767425, 106.693895, "Miền Nam" },

                    { "Cố đô Huế", "Dấu ấn triều đại",
                            "Từng là thủ phủ của triều đại nhà Nguyễn, quần thể di tích cố đô hiện lên với vẻ đẹp thâm nghiêm, cổ kính và tráng lệ. Bước qua cổng Ngọ Môn, du khách sẽ lạc vào không gian của những cung điện, đền đài được chạm trổ hoa văn rồng phượng tinh xảo. Xa xa ngoài ngoại ô là hệ thống lăng tẩm của các vị vua, được xây dựng hài hòa với phong thủy sông núi thiên nhiên. Nét duyên dáng của tà áo dài bên dòng sông Hương thơ mộng cùng nhã nhạc cung đình càng làm say lòng biết bao du khách.",
                            "https://upload.wikimedia.org/wikipedia/commons/c/cc/Ngomon2.jpg",
                            "Lịch sử", "Lịch sử,Cố đô", 16.463713, 107.579326, "Miền Trung" },

                    { "Chợ Lớn (Bình Tây)", "Văn hóa Hoa kiều",
                            "Tọa lạc tại khu vực Quận 6, ngôi chợ này là minh chứng rõ nét nhất cho sự phát triển của cộng đồng người Hoa tại Sài Gòn. Kiến trúc chợ vô cùng độc đáo với hình bát quái, mái ngói âm dương và những góc sân ngập tràn ánh nắng. Đây là đầu mối bán sỉ khổng lồ, cung cấp mọi mặt hàng từ nhu yếu phẩm, bánh kẹo đến thuốc Bắc truyền thống. Dạo quanh khu vực này, bạn còn được lấp đầy chiếc bụng đói bằng những món ẩm thực trứ danh như hủ tiếu, sủi cảo hay chè người Hoa.",
                            "https://upload.wikimedia.org/wikipedia/commons/b/bf/Vn-hcm-cho-binh-tay-27-07-07.JPG",
                            "Ẩm thực", "Mua sắm,Ẩm thực", 10.750058, 106.650893, "Miền Nam" },

                    { "Đà Lạt", "Thành phố ngàn hoa",
                            "Nằm trên cao nguyên Lâm Viên lộng gió, thành phố mờ sương được thiên nhiên ưu ái ban tặng khí hậu mát lạnh quanh năm. Cảnh sắc nơi đây đẹp tựa một bức tranh với những rừng thông bạt ngàn, hồ nước tĩnh lặng và những cánh đồng hoa rực rỡ sắc màu. Những ngôi biệt thự cổ mang kiến trúc Pháp ẩn mình dưới tán cây càng tôn lên vẻ lãng mạn, cổ tích của Đà Lạt. Thưởng thức một ly cà phê nóng hổi hay ăn chiếc bánh tráng nướng giữa tiết trời se lạnh là trải nghiệm không thể tuyệt vời hơn.",
                            "https://upload.wikimedia.org/wikipedia/commons/a/a2/Xuan_Huong_Lake_11.jpg",
                            "Núi", "Cao nguyên,Hoa", 11.940419, 108.458313, "Miền Núi" },

                    { "Đầm Sen Water Park", "Ốc đảo mát mẻ",
                            "Giữa cái nắng oi ả của phương Nam, công viên nước khổng lồ này giống như một ốc đảo giải nhiệt tuyệt vời. Khu vui chơi sở hữu hơn 30 thiết bị trò chơi dưới nước hiện đại, phù hợp cho mọi lứa tuổi từ trẻ em đến người lớn. Bạn có thể thử thách lòng dũng cảm với các máng trượt cảm giác mạnh, hay thả mình thư giãn trên dòng sông lười uốn lượn. Bao quanh các hồ bơi là hệ thống cây xanh mát mẻ, biến nơi đây thành điểm đến hoàn hảo cho các chuyến dã ngoại cuối tuần của gia đình.",
                            "https://upload.wikimedia.org/wikipedia/commons/thumb/3/36/Dam-sen-tuonglamphotos.jpg/3840px-Dam-sen-tuonglamphotos.jpg",
                            "Giải trí", "Vui chơi,Gia đình", 10.767931, 106.638515, "Miền Nam" },

                    { "Vịnh Hạ Long", "Di sản thiên nhiên thế giới",
                            "Kỳ quan thiên nhiên thế giới này là một kiệt tác vĩ đại do tạo hóa ban tặng với hàng ngàn hòn đảo đá vôi kỳ vĩ. Các dãy núi đá nhô lên mặt nước xanh ngọc bích tạo thành những hình thù sinh động như hòn Trống Mái, hòn Đỉnh Hương. Ẩn sâu bên trong các hòn đảo là hệ thống hang động thạch nhũ lung linh, huyền ảo khiến ai cũng phải trầm trồ. Ngủ đêm trên du thuyền giữa vịnh và đón bình minh trên boong tàu là một đặc quyền trải nghiệm vô cùng lãng mạn và xa hoa.",
                            "https://upload.wikimedia.org/wikipedia/commons/e/e4/Ha_Long_Bay.jpg",
                            "Biển", "Vịnh,Thiên nhiên,Du thuyền", 20.910000, 107.183333, "Miền Bắc" },

                    { "Đảo Phú Quốc", "Đảo ngọc hoang sơ",
                            "Mệnh danh là Đảo Ngọc, hòn đảo lớn nhất Việt Nam này là thiên đường nhiệt đới với những bãi biển cát trắng mịn màng như Bãi Sao, Bãi Kem. Làn nước biển trong vắt nhìn thấu đáy là điều kiện lý tưởng để du khách tham gia lặn ngắm san hô và khám phá đại dương. Nơi đây còn níu chân du khách bởi những khu rừng nguyên sinh xanh mướt, làng chài yên bình và đặc sản nước mắm, hồ tiêu trứ danh. Hệ thống resort nghỉ dưỡng đẳng cấp quốc tế biến Phú Quốc thành điểm hẹn hoàn hảo để tạm trốn khỏi bộn bề cuộc sống.",
                            "https://upload.wikimedia.org/wikipedia/commons/thumb/6/6e/Bai-sao-phu-quoc-tuonglamphotos.jpg/3840px-Bai-sao-phu-quoc-tuonglamphotos.jpg",
                            "Biển", "Biển,Nghỉ dưỡng,Đảo", 10.22896, 103.95725, "Miền Nam" },

                    { "Sapa", "Thành phố trong sương",
                            "Chìm trong biển mây bồng bềnh của núi rừng Tây Bắc, thị trấn Sapa mang một vẻ đẹp hoang sơ và kỳ bí hiếm có. Bức tranh thiên nhiên nơi đây được dệt nên bởi những thửa ruộng bậc thang kỳ vĩ chuyển màu vàng óng mỗi độ thu về. Du khách sẽ được hòa mình vào nhịp sống bình dị của các bản làng dân tộc thiểu số, chiêm ngưỡng những bộ trang phục thổ cẩm rực rỡ. Đừng quên nướng một bắp ngô vỉa hè, nhâm nhi ly rượu táo mèo trong cái buốt lạnh của sương đêm Sapa.",
                            "https://upload.wikimedia.org/wikipedia/commons/thumb/b/b5/Fansipan_Cable_Car_and_Sa_Pa.jpg/3840px-Fansipan_Cable_Car_and_Sa_Pa.jpg",
                            "Núi", "Cảnh quan,Tây Bắc,Lạnh", 22.33636, 103.84379, "Miền Bắc" },

                    { "Đỉnh Fansipan", "Nóc nhà Đông Dương",
                            "Được mệnh danh là Nóc nhà Đông Dương, đỉnh núi cao hơn 3.100 mét này là khao khát chinh phục của hàng triệu du khách. Giờ đây, chuyến cáp treo ngoạn mục băng qua mây ngàn và thung lũng Mường Hoa đã hiện thực hóa giấc mơ chạm tay vào cõi Phật. Đặt chân lên đỉnh núi, bạn sẽ ngỡ ngàng trước biển mây trắng xóa cuồn cuộn dưới chân và quần thể tâm linh uy nghi sừng sững. Cảm giác đứng giữa đất trời bao la, hít căng lồng ngực bầu không khí trong trẻo ở độ cao kỷ lục là một kỷ niệm vô giá.",
                            "https://upload.wikimedia.org/wikipedia/commons/d/de/C%C3%A1p-treo-fansipan-17.jpg",
                            "Núi", "Fansipan,Khám phá,Mây", 22.30398, 103.77531, "Miền Bắc" },

                    { "Ẩm thực Đồng Xuân", "Hương vị Thủ đô",
                            "Ẩn mình đằng sau khu chợ truyền thống lớn nhất Hà Nội là một thiên đường ẩm thực vô cùng nhộn nhịp. Không gian nơi đây mang đậm chất phố cổ với những con ngõ nhỏ hẹp, bàn ghế nhựa đơn sơ nhưng lúc nào cũng tấp nập thực khách. Tại đây, bạn có thể thưởng thức trọn vẹn tinh hoa quà vặt thủ đô như bún ốc, cháo sườn, phở tíu hay bánh tôm nóng hổi. Mùi thơm nức mũi tỏa ra từ các gánh hàng rong cùng tiếng rôm rả nói cười tạo nên một nét duyên ngầm rất riêng của người Hà Thành.",
                            "https://upload.wikimedia.org/wikipedia/commons/6/6b/Ch%E1%BB%A3_%C4%90%E1%BB%93ng_Xu%C3%A2n_-_NKS.jpg",
                            "Ẩm thực", "Phố cổ,Món ngon,Hà Nội", 21.033333, 105.850000, "Miền Bắc" },

                    { "Thác Dray Nur", "Hùng vĩ Tây Nguyên",
                            "Chiều dài khổng lồ, dòng thác này hiện lên đầy kiêu hãnh và hùng vĩ giữa núi rừng Tây Nguyên đại ngàn. Nước từ trên cao đổ xuống tung bọt trắng xóa, tạo nên những màn sương mù mờ ảo và tiếng gầm rú vang dội cả một góc trời. Ẩn sau màng nước cuồn cuộn là những hang động kỳ bí chứa đựng nhiều truyền thuyết hấp dẫn của đồng bào dân tộc. Du khách có thể đi bộ xuyên rừng, đạp xe hay ngồi trên những tảng đá rêu phong để chiêm ngưỡng vẻ đẹp hoang dại đầy mê hoặc này.",
                            "https://upload.wikimedia.org/wikipedia/commons/9/9b/Draynur_falls.jpg",
                            "Núi", "Thiên nhiên,Thác", 12.5393, 107.8920, "Miền Núi" },

                    { "Biển Hồ Pleiku", "Đôi mắt Pleiku",
                            "Được ví như Đôi mắt Pleiku, hồ nước ngọt này thực chất là miệng của một ngọn núi lửa đã ngừng hoạt động hàng triệu năm. Mặt hồ phẳng lặng, xanh biếc quanh năm, phản chiếu bầu trời Tây Nguyên cao vợi như một tấm gương khổng lồ. Con đường rợp bóng cây thông uốn lượn dẫn xuống hồ mang đến cảm giác vô cùng bình yên và lãng mạn cho những tâm hồn mơ mộng. Ngắm nhìn những chiếc thuyền độc mộc trôi lững lờ trên sóng nước, bạn sẽ thấy mọi muộn phiền dường như tan biến.",
                            "https://upload.wikimedia.org/wikipedia/commons/c/c2/H%E1%BB%93_%C4%90%E1%BB%A9c_An.jpg",
                            "Giải trí", "Hồ,Thiên nhiên", 14.0531, 108.0053, "Miền Núi" },

                    { "Măng Đen", "Đà Lạt thứ hai",
                            "Ẩn mình giữa rừng nguyên sinh bạt ngàn của tỉnh Kon Tum, nơi đây được du khách ưu ái gọi bằng cái tên Đà Lạt thứ hai. Khí hậu quanh năm mát mẻ, trong lành, bao phủ bởi sương mù lãng mạn vào những buổi sớm mai. Khu du lịch sinh thái này nổi bật với hàng loạt hồ nước tĩnh lặng, những ngọn thác róc rách và rừng thông rì rào trong gió. Khung cảnh hoang sơ, chưa bị thương mại hóa nhiều khiến Măng Đen trở thành điểm đến lý tưởng để chữa lành tâm hồn.",
                            "https://upload.wikimedia.org/wikipedia/commons/thumb/d/d6/M%C4%83ng_%C4%90en_2.jpg/3840px-M%C4%83ng_%C4%90en_2.jpg",
                            "Núi", "Sinh thái,Trải nghiệm", 14.5956, 108.2863, "Miền Núi" },

                    { "Nhà Rông Kon Klor", "Niềm tự hào Ba Na",
                            "Tọa lạc bên dòng sông Đăk Bla hiền hòa, đây là ngôi nhà Rông có quy mô lớn và kiến trúc tinh xảo nhất Tây Nguyên. Mái nhà nhọn hoắt vươn thẳng lên bầu trời xanh như một mũi tên, tượng trưng cho sức mạnh và tinh thần bất khuất của người dân tộc Ba Na. Toàn bộ công trình được làm từ các vật liệu tự nhiên như gỗ, tre, nứa và tranh, gắn kết bằng lạt tre vô cùng chắc chắn. Cây cầu treo Kon Klor bằng sắt tuyệt đẹp nằm ngay gần đó cũng là một điểm nhấn tô điểm thêm cho vẻ đẹp của bản làng.",
                            "https://upload.wikimedia.org/wikipedia/commons/5/53/BahnarRong.jpg",
                            "Văn hóa", "Nhà Rông,Văn hóa", 14.3414, 108.0163, "Miền Núi" },

                    { "Trung Nguyên Legend", "Trải nghiệm hương vị",
                            "Làng cà phê trứ danh này là nơi để bạn thực sự đắm chìm vào văn hóa và nghệ thuật thưởng thức cà phê của Tây Nguyên. Không gian được thiết kế vô cùng tinh tế, kết hợp hài hòa giữa kiến trúc nhà dài truyền thống và những mảng xanh của vườn cây, thác nước nhân tạo. Du khách không chỉ được nếm thử những ly cà phê chồn hảo hạng mà còn hiểu thêm về quy trình rang xay, pha chế công phu. Cảm giác nhấm nháp vị đắng quyến rũ giữa tiếng nhạc du dương và không khí trong lành thực sự rất khó quên.",
                            "https://upload.wikimedia.org/wikipedia/commons/5/5a/Langcaphetrungnguyen.JPG",
                            "Ẩm thực", "Cà phê,Ẩm thực", 12.6841, 108.0269, "Miền Núi" },

                    { "Vườn quốc gia Yok Đôn", "Thiên nhiên hoang dã",
                            "Trải dài trên diện tích khổng lồ, đây là khu bảo tồn tự nhiên duy nhất tại Việt Nam sở hữu hệ sinh thái rừng khộp đặc trưng. Bức tranh thiên nhiên ở đây biến đổi kỳ diệu theo mùa, từ màu xanh um tùm vào mùa mưa chuyển sang sắc lá vàng rụng lãng mạn vào mùa khô. Đây là ngôi nhà chung của vô số loài động vật hoang dã quý hiếm, đặc biệt là những chú voi nhà thân thiện, hiền lành. Du khách có thể trải nghiệm cảm giác đi bộ dưới tán rừng, ngắm chim muông hoặc chèo thuyền xuôi theo dòng sông Sêrêpốk huyền thoại.",
                            "https://upload.wikimedia.org/wikipedia/commons/7/74/Yokdon01.JPG",
                            "Núi", "Rừng,Khám phá", 12.9231, 107.8105, "Miền Núi" },

                    { "Thác Bản Giốc", "Bản tình ca đại ngàn",
                            "Nằm hiền hòa trên đường biên giới Việt – Trung, đây là một trong những thác nước xuyên quốc gia lớn và đẹp nhất thế giới. Dòng thác được chia làm ba tầng bậc tung bọt trắng xóa, nước đổ ầm ầm xuống mặt sông Quây Sơn xanh ngắt như ngọc bích. Bao quanh thác là những cánh đồng lúa chín vàng và những ngọn núi đá vôi trùng điệp tạo nên một bức tranh sơn thủy hữu tình tuyệt mĩ. Chỉ cần ngồi trên chiếc bè tre bồng bềnh tiến lại gần chân thác, bạn sẽ cảm nhận được hơi nước mát lạnh và sự hùng vĩ choáng ngợp của thiên nhiên.",
                            "https://upload.wikimedia.org/wikipedia/commons/d/de/Thac_Ban_Gioc.jpg",
                            "Núi", "Thiên nhiên,Thác", 12.8687, 108.1884, "Miền Núi" }
            };

            for (Object[] place : placesData) {
                Category cat = categories.get((String) place[4]);
                if (cat == null)
                    cat = categories.get("Thành phố");

                Destination dest = Destination.builder()
                        .title((String) place[0])
                        .subtitle((String) place[1])
                        .description((String) place[2])
                        .imageUrl((String) place[3])
                        .region((String) place[8])
                        .category(cat)
                        .tags((String) place[5])
                        .latitude((Double) place[6])
                        .longitude((Double) place[7])
                        .build();
                newItems.add(dest);
            }
            destinationRepository.saveAll(newItems);
        }
        upsertFocusedDestinations(categories);
        return destinationRepository.findAll();
    }

    private void upsertFocusedDestinations(Map<String, Category> categories) {
        List<SeedDestination> seeds = List.of(
                seed("Chợ Bến Thành", "Biểu tượng mua sắm giữa trung tâm",
                        "Khu chợ lâu đời ở Quận 1, phù hợp để mua quà lưu niệm, thử món ăn địa phương và cảm nhận nhịp sống Sài Gòn.",
                        "https://upload.wikimedia.org/wikipedia/commons/thumb/9/91/Ben_Thanh_market_2.jpg/960px-Ben_Thanh_market_2.jpg",
                        CATEGORY_SHOPPING, "chợ,mua sắm,quà lưu niệm,ẩm thực,quận 1", 10.772596, 106.698020, CITY_HCMC,
                        "Quận 1", "Đường Lê Lợi, phường Bến Thành, Quận 1", TYPE_SHOPPING, PRICE_MODERATE,
                        10_000L, 500_000L, "07:00 - 19:00", "biểu tượng Sài Gòn,mua đặc sản,khu ăn uống trong chợ", "gia đình,du khách lần đầu,người thích mua sắm"),
                seed("Dinh Độc Lập", "Di tích lịch sử giữa lòng thành phố",
                        "Công trình gắn với nhiều dấu mốc lịch sử hiện đại, có khuôn viên rộng và các phòng trưng bày dễ tham quan trong nửa ngày.",
                        "https://diadiemvietnam.vn/wp-content/uploads/2023/08/Dinh-Doc-Lap.jpg",
                        CATEGORY_CULTURE_HISTORY, "lịch sử,kiến trúc,bảo tàng,quận 1", 10.777093, 106.695393, CITY_HCMC,
                        "Quận 1", "135 Nam Kỳ Khởi Nghĩa, phường Bến Thành, Quận 1", TYPE_CULTURE_HISTORY, PRICE_BUDGET,
                        40_000L, 65_000L, "08:00 - 15:30", "di tích quốc gia,kiến trúc hiện đại,khu hầm chỉ huy", "người thích lịch sử,học sinh sinh viên,du khách quốc tế"),
                seed("Nhà thờ Đức Bà", "Điểm check-in kiến trúc Pháp",
                        "Nhà thờ nổi bật với kiến trúc gạch đỏ và vị trí ngay trung tâm, thường được kết hợp tham quan cùng Bưu điện Thành phố.",
                        "https://upload.wikimedia.org/wikipedia/commons/thumb/d/d9/Notre_dame_saigon.jpg/960px-Notre_dame_saigon.jpg",
                        CATEGORY_CULTURE_HISTORY, "nhà thờ,kiến trúc,check-in,quận 1", 10.779785, 106.699018, CITY_HCMC,
                        "Quận 1", "01 Công xã Paris, phường Bến Nghé, Quận 1", TYPE_CULTURE_HISTORY, PRICE_FREE,
                        0L, 0L, "Tham quan bên ngoài cả ngày", "kiến trúc Pháp,ảnh check-in,gần Bưu điện Thành phố", "cặp đôi,người thích kiến trúc,du khách đi bộ trung tâm"),
                seed("Bưu điện Trung tâm Sài Gòn", "Không gian cổ điển gần Nhà thờ Đức Bà",
                        "Tòa nhà bưu điện cổ có mái vòm lớn, bản đồ xưa và nhiều quầy lưu niệm, rất thuận tiện cho lịch trình đi bộ Quận 1.",
                        "https://upload.wikimedia.org/wikipedia/commons/thumb/f/fb/Saigon_Central_Post_Office_2022.jpg/960px-Saigon_Central_Post_Office_2022.jpg",
                        CATEGORY_CULTURE_HISTORY, "bưu điện,kiến trúc,quà lưu niệm,quận 1", 10.779836, 106.700030, CITY_HCMC,
                        "Quận 1", "02 Công xã Paris, phường Bến Nghé, Quận 1", TYPE_CULTURE_HISTORY, PRICE_FREE,
                        0L, 0L, "07:00 - 18:00", "mái vòm cổ,bản đồ lịch sử,gửi bưu thiếp", "gia đình,người thích chụp ảnh,du khách lần đầu"),
                seed("Phố đi bộ Nguyễn Huệ", "Trục dạo chơi buổi tối ở Quận 1",
                        "Không gian đi bộ rộng nối UBND Thành phố với bến Bạch Đằng, nhiều quán cà phê, nhà hàng và hoạt động đường phố về đêm.",
                        "https://upload.wikimedia.org/wikipedia/commons/thumb/d/d1/Ho_Chi_Minh_City%2C_Saigon%2C_Vietnam_%2849579818542%29.jpg/960px-Ho_Chi_Minh_City%2C_Saigon%2C_Vietnam_%2849579818542%29.jpg",
                        CATEGORY_ENTERTAINMENT, "đi bộ,buổi tối,check-in,quận 1", 10.773822, 106.703138, CITY_HCMC,
                        "Quận 1", "Đường Nguyễn Huệ, phường Bến Nghé, Quận 1", TYPE_ENTERTAINMENT, PRICE_FREE,
                        0L, 0L, "Cả ngày, nhộn nhịp nhất sau 18:00", "không gian đi bộ,nhạc nước,sát bến Bạch Đằng", "nhóm bạn,cặp đôi,du khách thích buổi tối"),
                seed("Phố Tây Bùi Viện", "Khu phố đêm sôi động",
                        "Tuyến phố nhiều bar, pub, hàng ăn và khách du lịch quốc tế, phù hợp với người muốn trải nghiệm không khí náo nhiệt về đêm.",
                        "https://upload.wikimedia.org/wikipedia/commons/thumb/5/52/Bui_Vien_Walking_Street_1.jpg/3840px-Bui_Vien_Walking_Street_1.jpg",
                        CATEGORY_ENTERTAINMENT, "phố đêm,bar,pub,ăn uống,quận 1", 10.767425, 106.693895, CITY_HCMC,
                        "Quận 1", "Đường Bùi Viện, phường Phạm Ngũ Lão, Quận 1", TYPE_ENTERTAINMENT, PRICE_MODERATE,
                        50_000L, 300_000L, "18:00 - 02:00", "phố không ngủ,ẩm thực đường phố,bar và pub", "nhóm bạn,du khách thích nightlife,người trẻ"),
                seed("Bitexco Financial Tower", "Ngắm thành phố từ trên cao",
                        "Tòa tháp nổi bật ở trung tâm Quận 1, có khu mua sắm, nhà hàng và đài quan sát nhìn toàn cảnh sông Sài Gòn.",
                        "https://www.e-architect.com/images/jpgs/vietnam/hcm_financial_tower_a290411_9.jpg",
                        CATEGORY_ENTERTAINMENT, "view đẹp,skydeck,trung tâm thương mại,quận 1", 10.771613, 106.704758, CITY_HCMC,
                        "Quận 1", "02 Hải Triều, phường Bến Nghé, Quận 1", TYPE_ENTERTAINMENT, PRICE_PREMIUM,
                        200_000L, 300_000L, "09:30 - 21:30", "ngắm skyline,Sài Gòn Skydeck,gần phố Nguyễn Huệ", "cặp đôi,người thích chụp ảnh,du khách ngắn ngày"),
                seed("Cafe Apartment Nguyễn Huệ", "Chung cư cà phê nhiều góc check-in",
                        "Tòa chung cư cũ trên phố đi bộ Nguyễn Huệ với nhiều quán cà phê, cửa hàng nhỏ và ban công nhìn xuống trung tâm.",
                        "https://jackfruitadventure.com/wp-content/uploads/2024/07/cafe-apartment-building-1024x683.jpg",
                        CATEGORY_CAFE, "cafe,check-in,nguyễn huệ,quận 1", 10.773382, 106.703399, CITY_HCMC,
                        "Quận 1", "42 Nguyễn Huệ, phường Bến Nghé, Quận 1", TYPE_CAFE, PRICE_MODERATE,
                        50_000L, 150_000L, "09:00 - 22:00", "nhiều quán cà phê,view phố đi bộ,góc ảnh trẻ trung", "nhóm bạn,cặp đôi,người thích cafe"),
                seed("Bảo tàng Chứng tích Chiến tranh", "Không gian lịch sử nhiều cảm xúc",
                        "Bảo tàng trưng bày tư liệu, hình ảnh và hiện vật về chiến tranh, phù hợp cho lịch trình tìm hiểu văn hóa lịch sử tại Quận 3.",
                        "https://upload.wikimedia.org/wikipedia/commons/thumb/3/36/Vietnam-_War_Remnants_Museum.jpg/3840px-Vietnam-_War_Remnants_Museum.jpg",
                        CATEGORY_CULTURE_HISTORY, "bảo tàng,lịch sử,quận 3", 10.778103, 106.690182, CITY_HCMC,
                        "Quận 3", "28 Võ Văn Tần, phường Võ Thị Sáu, Quận 3", TYPE_CULTURE_HISTORY, PRICE_BUDGET,
                        40_000L, 40_000L, "07:30 - 17:30", "tư liệu chiến tranh,khu trưng bày ngoài trời,giáo dục lịch sử", "người thích lịch sử,học sinh sinh viên,du khách quốc tế"),
                seed("Hồ Con Rùa", "Điểm hẹn cafe vỉa hè Quận 3",
                        "Khu vòng xoay nổi tiếng với nhiều quán ăn vặt, trà sữa và cà phê xung quanh, hợp để ngồi chơi buổi chiều tối.",
                        "https://cdn3.ivivu.com/2022/10/h%E1%BB%93-con-r%C3%B9a-ivivu-12.jpg",
                        CATEGORY_CAFE, "cafe,ăn vặt,quận 3,buổi tối", 10.782878, 106.695680, CITY_HCMC,
                        "Quận 3", "Công trường Quốc tế, phường Võ Thị Sáu, Quận 3", TYPE_CAFE, PRICE_BUDGET,
                        30_000L, 100_000L, "16:00 - 23:00", "ăn vặt vỉa hè,không khí trẻ,gần trung tâm", "nhóm bạn,sinh viên,người thích cafe tối"),
                seed("Phở Hòa Pasteur", "Quán phở lâu năm ở Quận 3",
                        "Địa chỉ phở quen thuộc trên đường Pasteur, phù hợp cho du khách muốn thử một bữa ăn Việt Nam dễ tiếp cận ngay gần trung tâm.",
                        "https://upload.wikimedia.org/wikipedia/commons/5/53/Pho-Beef-Noodles-2008.jpg",
                        CATEGORY_FOOD, "phở,đặc sản,sáng,trưa,quận 3", 10.787140, 106.689873, CITY_HCMC,
                        "Quận 3", "260C Pasteur, phường Võ Thị Sáu, Quận 3", TYPE_FOOD, PRICE_BUDGET,
                        70_000L, 120_000L, "06:00 - 23:00", "phở bò,quán lâu năm,gần trung tâm", "du khách lần đầu,gia đình,người muốn ăn nhanh"),
                seed("Landmark 81", "Tổ hợp mua sắm và ngắm cảnh ở Bình Thạnh",
                        "Tòa nhà cao nổi bật bên sông Sài Gòn, có trung tâm thương mại, khu ăn uống, rạp chiếu phim và không gian ngắm thành phố.",
                        "https://upload.wikimedia.org/wikipedia/commons/thumb/4/4e/The_Landmark_81_at_night.jpg/1280px-The_Landmark_81_at_night.jpg",
                        CATEGORY_ENTERTAINMENT, "landmark 81,view đẹp,mua sắm,bình thạnh", 10.794697, 106.722240, CITY_HCMC,
                        "Bình Thạnh", "720A Điện Biên Phủ, phường 22, Bình Thạnh", TYPE_ENTERTAINMENT, PRICE_PREMIUM,
                        0L, 810_000L, "09:30 - 22:00", "tòa nhà cao nhất Việt Nam,trung tâm thương mại,view sông Sài Gòn", "gia đình,cặp đôi,người thích city view"),
                seed("Vinhomes Central Park", "Công viên ven sông rộng ở Bình Thạnh",
                        "Không gian xanh bên sông với bãi cỏ, hồ nước, khu vui chơi và góc nhìn đẹp về Landmark 81.",
                        "https://commons.wikimedia.org/wiki/Special:FilePath/C%C3%B4ng_vi%C3%AAn_Vinhomes_Central_Park%2C_B%C3%ACnh_Th%E1%BA%A1nh%2C_Th%C3%A0nh_ph%E1%BB%91_H%E1%BB%93_Ch%C3%AD_Minh_25-05-2024_1.jpg?width=1280",
                        CATEGORY_ENTERTAINMENT, "công viên,ven sông,bình thạnh,gia đình", 10.795215, 106.719903, CITY_HCMC,
                        "Bình Thạnh", "Khu đô thị Vinhomes Central Park, Bình Thạnh", TYPE_ENTERTAINMENT, PRICE_FREE,
                        0L, 0L, "05:00 - 22:00", "công viên ven sông,khu vui chơi,view Landmark 81", "gia đình,trẻ em,người thích đi dạo"),
                seed("Khu du lịch Bình Quới", "Không gian xanh kiểu Nam Bộ",
                        "Khu du lịch ven sông với nhà lá, ao cá, buffet cuối tuần và cảnh quan miền quê ngay trong thành phố.",
                        "https://bizweb.dktcdn.net/100/101/075/files/khu-du-lich-binh-quoi-ho-chi-minh.jpg?v=1734949274565",
                        CATEGORY_FOOD, "buffet,nam bộ,ven sông,bình thạnh", 10.831495, 106.733079, CITY_HCMC,
                        "Bình Thạnh", "1147 Bình Quới, phường 28, Bình Thạnh", TYPE_FOOD, PRICE_MODERATE,
                        150_000L, 350_000L, "09:00 - 22:00", "không gian miền quê,buffet cuối tuần,ven sông", "gia đình,nhóm bạn,người thích món Việt"),
                seed("Suối Tiên Theme Park", "Khu vui chơi lớn ở Thủ Đức",
                        "Công viên giải trí lâu đời với nhiều trò chơi, khu biển nhân tạo và các công trình lấy cảm hứng văn hóa dân gian.",
                        "https://www.vietnamonline.com/media/uploads/froala_editor/images/vno_ST22.jpg",
                        CATEGORY_ENTERTAINMENT, "công viên giải trí,trẻ em,thủ đức", 10.870702, 106.803383, CITY_HCMC,
                        "Thủ Đức", "120 Xa lộ Hà Nội, phường Tân Phú, Thủ Đức", TYPE_ENTERTAINMENT, PRICE_MODERATE,
                        150_000L, 300_000L, "08:00 - 17:00", "trò chơi gia đình,biển Tiên Đồng,khu văn hóa dân gian", "gia đình,trẻ em,nhóm bạn"),
                seed("Chùa Bửu Long", "Ngôi chùa kiến trúc Thái ở Thủ Đức",
                        "Không gian chùa nổi bật với bảo tháp vàng, khuôn viên yên tĩnh và nhiều góc chụp ảnh nhẹ nhàng.",
                        "https://cdn3.ivivu.com/2022/11/ch%C3%B9a-B%E1%BB%ADu-Long-ivivu.jpg",
                        CATEGORY_CULTURE_HISTORY, "chùa,kiến trúc,thủ đức,check-in", 10.826758, 106.829192, CITY_HCMC,
                        "Thủ Đức", "81 Nguyễn Xiển, phường Long Bình, Thủ Đức", TYPE_CULTURE_HISTORY, PRICE_FREE,
                        0L, 0L, "08:00 - 18:00", "bảo tháp vàng,không gian yên tĩnh,kiến trúc Đông Nam Á", "người thích văn hóa,cặp đôi,du khách thích ảnh đẹp"),
                seed("Thảo Điền", "Khu cafe và nhà hàng quốc tế",
                        "Khu vực nhiều quán cà phê, nhà hàng, boutique và không gian xanh, phù hợp cho lịch trình nhẹ nhàng ở phía Đông thành phố.",
                        "https://maisonoffice.vn/wp-content/uploads/2024/03/3-khu-thao-dien-toa-lac-tai-vi-tri-dac-dia-ngay-xa-lo-ha-noi.jpg",
                        CATEGORY_CAFE, "cafe,nhà hàng,thảo điền,thủ đức", 10.802509, 106.732549, CITY_HCMC,
                        "Thủ Đức", "Khu Thảo Điền, phường Thảo Điền, Thủ Đức", TYPE_CAFE, PRICE_MODERATE,
                        60_000L, 250_000L, "08:00 - 23:00", "nhiều cafe đẹp,nhà hàng quốc tế,khu expat", "cặp đôi,nhóm bạn,người thích cafe brunch"),
                seed("Hotel Majestic Saigon", "Khách sạn cổ ven sông Sài Gòn",
                        "Khách sạn lịch sử trên đường Đồng Khởi, phù hợp với du khách muốn nghỉ ở trung tâm Quận 1 và gần nhiều điểm tham quan.",
                        "https://commons.wikimedia.org/wiki/Special:FilePath/Hotel_Majestic_Saigon.jpg?width=1280",
                        CATEGORY_HOTEL, "khách sạn,quận 1,ven sông,sang trọng", 10.773244, 106.706721, CITY_HCMC,
                        "Quận 1", "01 Đồng Khởi, phường Bến Nghé, Quận 1", TYPE_HOTEL, PRICE_LUXURY,
                        2_500_000L, 6_000_000L, "Nhận phòng từ 14:00", "vị trí trung tâm,kiến trúc cổ,gần bến Bạch Đằng", "du khách nghỉ dưỡng,cặp đôi,khách công tác"),
                seed("Bãi Sau Vũng Tàu", "Bãi biển dài và đông vui",
                        "Bãi tắm phổ biến nhất Vũng Tàu, nhiều khách sạn, quán ăn và dịch vụ du lịch dọc đường Thùy Vân.",
                        "https://vielimousine.com/wp-content/uploads/2023/11/bai-sau-vung-tau.jpg",
                        CATEGORY_ENTERTAINMENT, "biển,bãi sau,tắm biển,vũng tàu", 10.335701, 107.090911, CITY_VUNG_TAU,
                        "Bãi Sau", "Đường Thùy Vân, thành phố Vũng Tàu", TYPE_ENTERTAINMENT, PRICE_FREE,
                        0L, 0L, "Cả ngày", "bãi tắm dài,nhiều khách sạn,gần khu hải sản", "gia đình,nhóm bạn,du khách cuối tuần"),
                seed("Bãi Trước Vũng Tàu", "Ngắm hoàng hôn và dạo biển",
                        "Khu bờ biển trung tâm có công viên, hàng cây và tầm nhìn đẹp về vịnh, phù hợp đi dạo chiều tối.",
                        "https://cdn.vntrip.vn/cam-nang/wp-content/uploads/2017/10/bai-truoc-1.jpg",
                        CATEGORY_ENTERTAINMENT, "biển,bãi trước,hoàng hôn,vũng tàu", 10.345214, 107.076032, CITY_VUNG_TAU,
                        "Bãi Trước", "Đường Quang Trung, thành phố Vũng Tàu", TYPE_ENTERTAINMENT, PRICE_FREE,
                        0L, 0L, "Cả ngày", "ngắm hoàng hôn,công viên ven biển,gần trung tâm", "cặp đôi,gia đình,người thích đi bộ"),
                seed("Tượng Chúa Kitô Vua", "Điểm ngắm biển trên Núi Nhỏ",
                        "Tượng Chúa lớn trên đỉnh Núi Nhỏ, cần leo bậc thang nhưng bù lại có góc nhìn rộng xuống biển Vũng Tàu.",
                        "https://dulichviet.net.vn/wp-content/uploads/2019/07/tuong-chua-kito-2.jpg",
                        CATEGORY_CULTURE_HISTORY, "tượng chúa,núi nhỏ,view biển,vũng tàu", 10.326529, 107.086756, CITY_VUNG_TAU,
                        "Núi Nhỏ", "01 Bà Rịa, phường 2, thành phố Vũng Tàu", TYPE_CULTURE_HISTORY, PRICE_FREE,
                        0L, 0L, "07:00 - 17:00", "leo bậc thang,view biển,tượng biểu tượng Vũng Tàu", "người thích vận động,du khách thích ngắm cảnh,cặp đôi"),
                seed("Hải đăng Vũng Tàu", "Cung đường ngắm thành phố từ cao",
                        "Ngọn hải đăng cổ trên Núi Nhỏ, đường lên có nhiều góc nhìn đẹp và quán ăn vặt nổi tiếng.",
                        "https://www.elle.vn/wp-content/uploads/2019/07/18/DJI_0133.jpg",
                        CATEGORY_CULTURE_HISTORY, "hải đăng,view đẹp,núi nhỏ,vũng tàu", 10.335091, 107.081927, CITY_VUNG_TAU,
                        "Núi Nhỏ", "Phường 2, thành phố Vũng Tàu", TYPE_CULTURE_HISTORY, PRICE_FREE,
                        0L, 10_000L, "07:00 - 22:00", "view toàn thành phố,cung đường đẹp,điểm chụp ảnh", "cặp đôi,nhóm bạn,người thích săn ảnh"),
                seed("Hồ Mây Park", "Khu vui chơi trên núi",
                        "Tổ hợp cáp treo, công viên giải trí và khu sinh thái trên Núi Lớn, phù hợp đi nửa ngày đến một ngày.",
                        "https://cdn3.ivivu.com/2024/01/ho-may-park-ivivu-9-1024x768.jpg",
                        CATEGORY_ENTERTAINMENT, "hồ mây,cáp treo,khu vui chơi,vũng tàu", 10.362098, 107.066751, CITY_VUNG_TAU,
                        "Núi Lớn", "01A Trần Phú, phường 1, thành phố Vũng Tàu", TYPE_ENTERTAINMENT, PRICE_PREMIUM,
                        400_000L, 500_000L, "08:00 - 18:00", "cáp treo,trò chơi gia đình,view Núi Lớn", "gia đình,trẻ em,nhóm bạn"),
                seed("Mũi Nghinh Phong", "Mũi đất nhiều góc chụp ảnh",
                        "Điểm check-in nằm giữa Bãi Sau và Bãi Dứa, có gió biển mạnh, view biển mở và các lối đi đá đẹp.",
                        "https://media.gody.vn/images/ba-ria-vung-tau/khu-du-lich-mui-nghinh-phong/12-2017/94000648-20171228071615-ba-ria-vung-tau-khu-du-lich-mui-nghinh-phong.jpg",
                        CATEGORY_ENTERTAINMENT, "check-in,biển,mũi nghinh phong,vũng tàu", 10.323958, 107.088586, CITY_VUNG_TAU,
                        "Bãi Dứa", "Số 1 Hạ Long, phường 2, thành phố Vũng Tàu", TYPE_ENTERTAINMENT, PRICE_FREE,
                        0L, 0L, "Cả ngày", "view biển rộng,góc ảnh đẹp,gần Tượng Chúa", "cặp đôi,nhóm bạn,người thích chụp ảnh"),
                seed("Chợ đêm Hải sản Vũng Tàu", "Ăn hải sản gần Bãi Sau",
                        "Khu ăn uống buổi tối tập trung nhiều quầy hải sản, phù hợp cho nhóm bạn muốn ăn no sau khi tắm biển.",
                        "https://www.dulichthienthai.com/wp-content/uploads/2022/05/cho-dem-vung-tau-cho-hai-san-vung-tau-gia-re.jpg",
                        CATEGORY_FOOD, "hải sản,chợ đêm,bãi sau,vũng tàu", 10.337792, 107.088363, CITY_VUNG_TAU,
                        "Bãi Sau", "Khu vực sau khách sạn Imperial, gần đường Thùy Vân", TYPE_FOOD, PRICE_MODERATE,
                        100_000L, 400_000L, "17:00 - 23:30", "hải sản nướng,không khí buổi tối,gần Bãi Sau", "nhóm bạn,gia đình,người thích hải sản"),
                seed("Bánh khọt Gốc Vú Sữa", "Đặc sản bánh khọt Vũng Tàu",
                        "Quán bánh khọt nổi tiếng với bánh giòn, tôm tươi và rau sống, thường đông vào cuối tuần.",
                        "https://images.squarespace-cdn.com/content/v1/538bdee5e4b0db4eab0960f9/1607990408395-3ZW2HACVY4HAY4VMZ6EO/1.jpg",
                        CATEGORY_FOOD, "bánh khọt,đặc sản,vũng tàu,ăn trưa", 10.346061, 107.084358, CITY_VUNG_TAU,
                        "Trung tâm", "14 Nguyễn Trường Tộ, phường 2, thành phố Vũng Tàu", TYPE_FOOD, PRICE_BUDGET,
                        40_000L, 100_000L, "06:00 - 14:30", "bánh khọt đặc sản,tôm tươi,quán lâu năm", "du khách lần đầu,gia đình,người thích món địa phương"),
                seed("Gành Hào Vũng Tàu", "Nhà hàng hải sản nhìn ra biển",
                        "Địa chỉ hải sản quen thuộc ở đường Trần Phú, hợp cho bữa tối gia đình hoặc nhóm bạn muốn ngồi lâu.",
                        "https://yeuvungtau.com/wp-content/uploads/2023/03/nha-hang-ganh-hao-2-vung-tau-1.jpg",
                        CATEGORY_FOOD, "hải sản,nhà hàng,view biển,vũng tàu", 10.361437, 107.066903, CITY_VUNG_TAU,
                        "Bãi Dâu", "03 Trần Phú, phường 5, thành phố Vũng Tàu", TYPE_FOOD, PRICE_PREMIUM,
                        150_000L, 600_000L, "10:00 - 22:00", "hải sản tươi,view biển,phù hợp đi nhóm", "gia đình,nhóm bạn,khách công tác"),
                seed("The Imperial Hotel Vũng Tàu", "Khách sạn gần Bãi Sau",
                        "Khách sạn phong cách cổ điển nằm sát khu Bãi Sau, phù hợp với du khách muốn nghỉ dưỡng tiện ra biển.",
                        "https://commons.wikimedia.org/wiki/Special:FilePath/The_Imperial_Hotel.jpg?width=1280",
                        CATEGORY_HOTEL, "khách sạn,bãi sau,nghỉ dưỡng,vũng tàu", 10.337222, 107.090558, CITY_VUNG_TAU,
                        "Bãi Sau", "159 Thùy Vân, phường Thắng Tam, thành phố Vũng Tàu", TYPE_HOTEL, PRICE_LUXURY,
                        2_500_000L, 5_500_000L, "Nhận phòng từ 15:00", "gần biển,phong cách cổ điển,hợp nghỉ dưỡng", "cặp đôi,gia đình,du khách nghỉ cuối tuần"),
                seed("Lotte Mart Vũng Tàu", "Mua sắm và ăn uống trong nhà",
                        "Trung tâm thương mại dễ ghé khi trời mưa hoặc cần mua đồ dùng, có siêu thị, khu ăn uống và rạp chiếu phim.",
                        "https://cbm.com.vn/img_data/images/upload/construction/pcchinh_1410336684.jpg",
                        CATEGORY_SHOPPING, "mua sắm,siêu thị,ăn uống,trời mưa,vũng tàu", 10.350824, 107.095473, CITY_VUNG_TAU,
                        "Trung tâm", "Góc đường 3/2 và Thi Sách, thành phố Vũng Tàu", TYPE_SHOPPING, PRICE_MODERATE,
                        30_000L, 1_000_000L, "08:00 - 22:00", "siêu thị,khu ăn uống,rạp phim", "gia đình,du khách cần mua sắm,ngày mưa")
        );

        List<Destination> toSave = new ArrayList<>();
        for (SeedDestination seed : seeds) {
            Destination destination = findSeedDestination(seed).orElseGet(Destination::new);
            applySeed(destination, seed, categories);
            toSave.add(destination);
        }
        destinationRepository.saveAll(toSave);
    }

    private Optional<Destination> findSeedDestination(SeedDestination seed) {
        Optional<Destination> exact = destinationRepository
                .findFirstByTitleIgnoreCaseAndCityIgnoreCase(seed.title(), seed.city());
        if (exact.isPresent()) {
            return exact;
        }

        return destinationRepository.findByTitleIgnoreCase(seed.title()).stream()
                .filter(destination -> isBlank(destination.getCity())
                        || seed.city().equalsIgnoreCase(destination.getCity()))
                .findFirst();
    }

    private void applySeed(Destination destination, SeedDestination seed, Map<String, Category> categories) {
        destination.setTitle(seed.title());
        destination.setSubtitle(seed.subtitle());
        destination.setDescription(seed.description());
        destination.setImageUrl(seed.imageUrl());
        destination.setRegion(seed.city());
        destination.setCity(seed.city());
        destination.setDistrict(seed.district());
        destination.setAddress(seed.address());
        destination.setPlaceType(seed.placeType());
        destination.setPriceLevel(seed.priceLevel());
        destination.setMinPrice(seed.minPrice());
        destination.setMaxPrice(seed.maxPrice());
        destination.setOpeningHours(seed.openingHours());
        destination.setHighlights(seed.highlights());
        destination.setSuitableFor(seed.suitableFor());
        destination.setTags(seed.tags());
        destination.setLatitude(seed.latitude());
        destination.setLongitude(seed.longitude());
        destination.setCategory(ensureCategory(categories, seed.categoryName(), iconForCategory(seed.categoryName())));
    }

    private String iconForCategory(String categoryName) {
        return switch (categoryName) {
            case CATEGORY_FOOD -> "restaurant";
            case CATEGORY_ENTERTAINMENT -> "local_play";
            case CATEGORY_HOTEL -> "hotel";
            case CATEGORY_CAFE -> "local_cafe";
            case CATEGORY_CULTURE_HISTORY -> "museum";
            case CATEGORY_SHOPPING -> "shopping_bag";
            default -> "place";
        };
    }

    private boolean isBlank(String value) {
        return value == null || value.isBlank();
    }

    private SeedDestination seed(
            String title,
            String subtitle,
            String description,
            String imageUrl,
            String categoryName,
            String tags,
            Double latitude,
            Double longitude,
            String city,
            String district,
            String address,
            String placeType,
            String priceLevel,
            Long minPrice,
            Long maxPrice,
            String openingHours,
            String highlights,
            String suitableFor) {
        return new SeedDestination(
                title,
                subtitle,
                description,
                imageUrl,
                categoryName,
                tags,
                latitude,
                longitude,
                city,
                district,
                address,
                placeType,
                priceLevel,
                minPrice,
                maxPrice,
                openingHours,
                highlights,
                suitableFor);
    }

    private record SeedDestination(
            String title,
            String subtitle,
            String description,
            String imageUrl,
            String categoryName,
            String tags,
            Double latitude,
            Double longitude,
            String city,
            String district,
            String address,
            String placeType,
            String priceLevel,
            Long minPrice,
            Long maxPrice,
            String openingHours,
            String highlights,
            String suitableFor) {
    }

    private List<User> ensureUsers() {
        long existing = userRepository.count();
        int target = 25;
        if (existing < target) {
            List<User> users = new ArrayList<>();
            for (int i = (int) existing + 1; i <= target; i++) {
                users.add(User.builder()
                        .username("user" + i)
                        .password("password123")
                        .email("user" + i + "@example.com")
                        .fullName("User " + i)
                        .avatarUrl("https://i.pravatar.cc/150?img=" + ((i % 70) + 1))
                        .role(User.Role.USER)
                        .build());
            }
            userRepository.saveAll(users);
        }
        return userRepository.findAll();
    }

    private void ensureReviews(List<Destination> destinations) {
        for (Destination destination : destinations) {
            List<Review> reviews = reviewRepository.findByDestination_IdOrderByCreatedAtDesc(destination.getId());
            if (reviews.isEmpty()) {
                destination.setReviewCount(0);
                destination.setRating(0.0);
                continue;
            }
            int count = reviews.size();
            int sum = reviews.stream().mapToInt(Review::getRating).sum();
            destination.setReviewCount(count);
            destination.setRating(sum / (double) count);
        }
        destinationRepository.saveAll(destinations);
    }
}
