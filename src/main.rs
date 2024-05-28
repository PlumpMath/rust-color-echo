use colored::*;
use std::env;
use fastrand;
use std::char;

fn main() {
    let mut args: Vec<String> = env::args().skip(1).collect();

    // 인자가 하나만 있는 경우 그 인자를 공백으로 분할
    if args.len() == 1 && args[0].contains(' ') {
        args = args[0].split_whitespace().map(String::from).collect();
    }

    // // 이모지 범위 설정
    // let emoji_start = 0x1F600;
    // let emoji_end = 0x1F64F;
	// 이모지 범위 배열
    let emoji_ranges = [
        (0x1F600, 0x1F64F), // 표정 이모티콘
        (0x1F900, 0x1F9FF), // 추가 이모티콘
        (0x1F400, 0x1F4FF), // 동물 및 자연
        (0x1F340, 0x1F37F), // 음식 및 음료
        (0x1F3A0, 0x1F3FF), // 활동 및 스포츠
        (0x1F680, 0x1F6FF), // 여행 및 장소
        (0x1F900, 0x1F9FF), // 기타 오브젝트
    ];

    // 랜덤 범위 선택
    let (emoji_start, emoji_end) = emoji_ranges[fastrand::usize(0..emoji_ranges.len())];

    // 랜덤 유니코드 코드 포인트 생성
    let emoji_code = fastrand::u32(emoji_start..=emoji_end);

    // 유니코드 코드 포인트를 char로 변환하여 이모지 선택
    let emoji = char::from_u32(emoji_code).unwrap_or('❓'); // 변환 실패 시 기본 이모지 사용

    let colored_text: Vec<String> = args.iter().map(|word| {
        // fastrand를 사용하여 0과 255 사이의 랜덤 RGB 값을 생성
        let r = fastrand::u8(100..255);
        let g = fastrand::u8(100..255);
        let b = fastrand::u8(100..255);

        // 생성된 RGB 값을 사용하여 텍스트의 색상을 설정
        word.truecolor(r, g, b).to_string()
    }).collect();

    // 색상이 적용된 텍스트를 공백으로 구분하여 출력, 처음과 끝에 랜덤 이모지 추가
    println!("{} {} {}", emoji, colored_text.join(" "), emoji);
}

