package com.vn.huit.travelApp.config;

import com.vn.huit.travelApp.entity.Category;
import com.vn.huit.travelApp.entity.Destination;
import com.vn.huit.travelApp.entity.Favorite;
import com.vn.huit.travelApp.entity.Review;
import com.vn.huit.travelApp.entity.User;
import com.vn.huit.travelApp.repository.CategoryRepository;
import com.vn.huit.travelApp.repository.DestinationRepository;
import com.vn.huit.travelApp.repository.FavoriteRepository;
import com.vn.huit.travelApp.repository.ReviewRepository;
import com.vn.huit.travelApp.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Random;

@Configuration
@RequiredArgsConstructor
public class DataSeeder {

    private final CategoryRepository categoryRepository;
    private final DestinationRepository destinationRepository;
    private final ReviewRepository reviewRepository;
    private final UserRepository userRepository;
    private final FavoriteRepository favoriteRepository;

    @Bean
    public CommandLineRunner initData() {
        return args -> {
            Map<String, Category> categories = ensureCategories();
            List<Destination> destinations = ensureDestinations(categories);
            List<User> users = ensureUsers();
            ensureReviews(destinations);
            ensureFavorites(destinations, users);
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
        return map;
    }

    private List<Destination> ensureDestinations(Map<String, Category> categories) {
        long existing = destinationRepository.count();
        if (existing > 0) {
            return destinationRepository.findAll();
        }
        {
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
        return destinationRepository.findAll();
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
        long existing = reviewRepository.count();
        int target = 30;
        if (existing >= target) {
            return;
        }
        int missing = (int) (target - existing);
        List<User> users = userRepository.findAll();
        if (users.isEmpty()) return;
        String[] comments = {
                "Cảnh đẹp, dịch vụ tốt.",
                "Trải nghiệm đáng nhớ.",
                "Không khí dễ chịu và đồ ăn ngon.",
                "Rất đáng để quay lại.",
                "Tuyệt vời cho kỳ nghỉ cuối tuần."
        };

        Random random = new Random(42);
        List<Review> newReviews = new ArrayList<>();
        for (int i = 0; i < missing; i++) {
            Destination destination = destinations.get(random.nextInt(destinations.size()));
            User user = users.get(i % users.size());
            Review review = Review.builder()
                    .user(user)
                    .rating(3 + random.nextInt(3))
                    .comment(comments[i % comments.length])
                    .createdAt(LocalDateTime.now().minusDays(random.nextInt(60) + 1))
                    .destination(destination)
                    .build();
            newReviews.add(review);
        }
        reviewRepository.saveAll(newReviews);

        for (Destination destination : destinations) {
            List<Review> reviews = reviewRepository.findByDestination_IdOrderByCreatedAtDesc(destination.getId());
            if (reviews.isEmpty()) {
                continue;
            }
            int count = reviews.size();
            int sum = reviews.stream().mapToInt(Review::getRating).sum();
            destination.setReviewCount(count);
            destination.setRating(sum / (double) count);
        }
        destinationRepository.saveAll(destinations);
    }

    private void ensureFavorites(List<Destination> destinations, List<User> users) {
        long existing = favoriteRepository.count();
        int target = 30;
        if (existing >= target || users.isEmpty()) {
            return;
        }
        Random random = new Random(24);
        int attempts = 0;
        while (favoriteRepository.count() < target && attempts < target * 5) {
            User user = users.get(random.nextInt(users.size()));
            Destination destination = destinations.get(random.nextInt(destinations.size()));
            if (!favoriteRepository.existsByUser_UsernameAndDestination_Id(user.getUsername(), destination.getId())) {
                favoriteRepository.save(Favorite.builder()
                        .user(user)
                        .destination(destination)
                        .build());
            }
            attempts++;
        }
    }
}
