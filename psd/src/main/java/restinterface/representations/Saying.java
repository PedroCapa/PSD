package restinterface.representations;

import com.fasterxml.jackson.annotation.*;

public class Saying {
    public final String description;
    public final String content;
    @JsonCreator
    public Saying(@JsonProperty("content") String content, @JsonProperty("description") String description) {
      this.description = description;
      this.content = content;
    }
}

