import React from "react";
import {registerRoot, Composition} from "remotion";
import {NovaVerticalVideo, type VideoProps} from "./Video";

const defaultProps: VideoProps = {
  title: "حوّل فكرتك إلى خطوة عملية",
  hook: "هل تريد أن تبدأ مشروعاً بميزانية صفر؟",
  scenes: [
    {heading: "ابدأ بمشكلة واضحة", body: "اختر مشكلة حقيقية يواجهها الناس، ولا تبدأ ببناء شيء لا يحتاجه أحد."},
    {heading: "اختبر قبل أن تصرف", body: "اصنع نموذجاً بسيطاً، واعرضه على مستخدمين حقيقيين، واجمع ملاحظاتهم."},
    {heading: "طوّر خطوة بخطوة", body: "استخدم الأدوات المجانية أولاً، وقِس النتيجة قبل توسيع المشروع."},
  ],
  closing: "خطوة صغيرة اليوم تصنع فرقاً",
  brand: "NOVA",
};

const Root: React.FC = () => (
  <>
    <Composition
      id="NovaVerticalVideo"
      component={NovaVerticalVideo}
      durationInFrames={30 * 20}
      fps={30}
      width={1080}
      height={1920}
      defaultProps={defaultProps}
      calculateMetadata={({props}) => ({
        durationInFrames: Math.max(30, (props.scenes.length + 2) * 150),
      })}
    />
  </>
);

registerRoot(Root);
