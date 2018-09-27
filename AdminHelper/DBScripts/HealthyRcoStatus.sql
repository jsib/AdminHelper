USE [ADMIN]
GO

/****** Object:  Table [dbo].[HealthyRcoStatus]    Script Date: 27.09.2018 18:10:22 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[HealthyRcoStatus](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[date] [datetime] NOT NULL,
	[code] [nvarchar](max) NOT NULL,
	[server] [varchar](50) NULL,
	[process_size] [int] NULL,
	[start_duration] [smallint] NULL,
	[step] [int] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

